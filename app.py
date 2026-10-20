# -*- coding: utf-8 -*-
"""考研备考监督打卡与激励管理系统 —— Flask 后端"""
import pymysql
from flask import Flask, request, jsonify, render_template, session, redirect, url_for
from werkzeug.security import generate_password_hash, check_password_hash
from config import DB_CONFIG

app = Flask(__name__)
app.secret_key = "kaoyan-checkin-secret"


def get_db():
    return pymysql.connect(
        host=DB_CONFIG["host"], user=DB_CONFIG["user"],
        password=DB_CONFIG["password"], database=DB_CONFIG["database"],
        charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor
    )


# ---------- 页面路由 ----------
@app.route("/")
def index():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("index.html", nickname=session.get("nickname"))


@app.route("/login")
def login():
    return render_template("login.html")


@app.route("/goals")
def goals_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("goals.html", nickname=session.get("nickname"))


@app.route("/plans")
def plans_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("plans.html", nickname=session.get("nickname"))


@app.route("/tasks")
def tasks_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("tasks.html", nickname=session.get("nickname"))


@app.route("/checkin")
def checkin_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("checkin.html", nickname=session.get("nickname"))


@app.route("/supervise")
def supervise_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("supervise.html", nickname=session.get("nickname"))


@app.route("/rewards")
def rewards_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("rewards.html", nickname=session.get("nickname"))


# ---------- 用户注册与登录 ----------
@app.route("/api/register", methods=["POST"])
def register():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO `User`(`手机号`,`昵称`,`密码`) VALUES (%s,%s,%s)",
            (data["phone"], data["nickname"],
             generate_password_hash(data["password"])),
        )
        conn.commit()
        return jsonify({"code": 0, "msg": "注册成功"})
    except pymysql.err.IntegrityError:
        return jsonify({"code": 1, "msg": "手机号或昵称已存在"})
    finally:
        cur.close()
        conn.close()


@app.route("/api/login", methods=["POST"])
def login_api():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM `User` WHERE `手机号`=%s", (data["phone"],))
    user = cur.fetchone()
    cur.close()
    conn.close()
    if user and user["密码"] == data["password"]:
        session["uid"] = user["用户ID"]
        session["nickname"] = user["昵称"]
        return jsonify({"code": 0, "msg": "登录成功", "nickname": user["昵称"]})
    return jsonify({"code": 1, "msg": "手机号或密码错误"})


@app.route("/api/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


# ---------- 目标管理 ----------
@app.route("/api/goals", methods=["GET", "POST"])
def goals():
    conn = get_db()
    cur = conn.cursor()
    if request.method == "GET":
        cur.execute("SELECT * FROM `Goal` WHERE `用户ID`=%s", (session["uid"],))
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({"code": 0, "data": rows})
    data = request.json
    cur.execute(
        "INSERT INTO `Goal`(`用户ID`,`目标院校`,`目标专业`,`目标分数`,`备考阶段`,`开始日期`,`结束日期`) "
        "VALUES (%s,%s,%s,%s,%s,%s,%s)",
        (session["uid"], data["school"], data["major"], data["score"],
         data["stage"], data["start"], data["end"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "目标已创建"})


# ---------- 任务管理 ----------
@app.route("/api/tasks", methods=["GET", "POST"])
def tasks():
    conn = get_db()
    cur = conn.cursor()
    if request.method == "GET":
        cur.execute(
            "SELECT t.* FROM `Task` t JOIN `Plan` p ON t.`计划ID`=p.`计划ID` "
            "JOIN `Goal` g ON p.`目标ID`=g.`目标ID` WHERE g.`用户ID`=%s ORDER BY t.`截止时间`",
            (session["uid"],))
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({"code": 0, "data": rows})
    data = request.json
    cur.execute(
        "INSERT INTO `Task`(`计划ID`,`任务名称`,`科目`,`预计时长`,`优先级`,`截止时间`) "
        "VALUES (%s,%s,%s,%s,%s,%s)",
        (data["plan_id"], data["name"], data["subject"],
         data["duration"], data["priority"], data["deadline"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "任务已创建"})


# ---------- 每日打卡（调用存储过程：打卡+积分+状态更新） ----------
@app.route("/api/checkin", methods=["POST"])
def checkin():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.callproc("sp_checkin_and_award",
                 (session["uid"], data["task_id"], data["complete_time"],
                  data.get("image_url", ""), 0))
    cur.execute("SELECT @_sp_checkin_and_award_4 AS cid")
    cid = cur.fetchone()["cid"]
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "打卡成功，积分已发放", "checkin_id": cid})


# ---------- 研友监督 ----------
@app.route("/api/supervise", methods=["GET", "POST"])
def supervise():
    conn = get_db()
    cur = conn.cursor()
    if request.method == "GET":
        cur.execute(
            "SELECT s.`监督ID`, u.`用户ID`, u.`昵称` FROM `Supervise` s "
            "JOIN `User` u ON s.`研友ID`=u.`用户ID` "
            "WHERE s.`用户ID`=%s AND s.`状态`='有效'",
            (session["uid"],))
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({"code": 0, "data": rows})
    data = request.json
    cur.execute("SELECT `用户ID` FROM `User` WHERE `手机号`=%s", (data["phone"],))
    peer = cur.fetchone()
    if not peer:
        cur.close()
        conn.close()
        return jsonify({"code": 1, "msg": "未找到该手机号用户"})
    cur.execute(
        "INSERT INTO `Supervise`(`用户ID`,`研友ID`,`状态`) VALUES (%s,%s,'有效')",
        (session["uid"], peer["用户ID"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "监督关系已建立"})


# ---------- 统计与排行（视图查询） ----------
@app.route("/api/stats")
def stats():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM `v_user_checkin_stats` WHERE `用户ID`=%s",
                (session["uid"],))
    checkin_stats = cur.fetchone()
    cur.execute("SELECT * FROM `v_points_rank` WHERE `用户ID`=%s",
                (session["uid"],))
    rank = cur.fetchone()
    cur.execute("SELECT * FROM `v_task_completion_stats` WHERE `用户ID`=%s",
                (session["uid"],))
    task_stats = cur.fetchone()
    cur.execute("SELECT * FROM `v_points_rank` ORDER BY `总积分` DESC LIMIT 10")
    top10 = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "checkin": checkin_stats, "rank": rank,
                    "task": task_stats, "top10": top10})


# ---------- 阶段计划管理 ----------
@app.route("/api/plans", methods=["GET", "POST"])
def plans():
    conn = get_db()
    cur = conn.cursor()
    if request.method == "GET":
        cur.execute(
            "SELECT p.*, g.`目标院校`, g.`目标专业` FROM `Plan` p "
            "JOIN `Goal` g ON p.`目标ID`=g.`目标ID` WHERE g.`用户ID`=%s "
            "ORDER BY p.`开始日期`", (session["uid"],))
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({"code": 0, "data": rows})
    data = request.json
    cur.execute(
        "INSERT INTO `Plan`(`目标ID`,`阶段`,`计划名称`,`开始日期`,`结束日期`) "
        "VALUES (%s,%s,%s,%s,%s)",
        (data["goal_id"], data["stage"], data["name"],
         data["start"], data["end"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "计划已创建"})


@app.route("/api/plans/<int:plan_id>", methods=["DELETE"])
def delete_plan(plan_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "DELETE p FROM `Plan` p JOIN `Goal` g ON p.`目标ID`=g.`目标ID` "
        "WHERE p.`计划ID`=%s AND g.`用户ID`=%s", (plan_id, session["uid"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "计划已删除"})


# ---------- 目标删除 ----------
@app.route("/api/goals/<int:goal_id>", methods=["DELETE"])
def delete_goal(goal_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM `Goal` WHERE `目标ID`=%s AND `用户ID`=%s",
                (goal_id, session["uid"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "目标已删除"})


# ---------- 任务状态更新 ----------
@app.route("/api/tasks/<int:task_id>", methods=["PUT"])
def update_task(task_id):
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "UPDATE `Task` t JOIN `Plan` p ON t.`计划ID`=p.`计划ID` "
        "JOIN `Goal` g ON p.`目标ID`=g.`目标ID` "
        "SET t.`完成状态`=%s WHERE t.`任务ID`=%s AND g.`用户ID`=%s",
        (data["status"], task_id, session["uid"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "任务状态已更新"})


# ---------- 打卡记录查询 ----------
@app.route("/api/checkin", methods=["GET"])
def checkin_history():
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT c.*, t.`任务名称`, t.`科目` FROM `Checkin` c "
        "JOIN `Task` t ON c.`任务ID`=t.`任务ID` "
        "WHERE c.`用户ID`=%s ORDER BY c.`打卡时间戳` DESC LIMIT 50",
        (session["uid"],))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "data": rows})


# ---------- 勋章管理 ----------
@app.route("/api/badges")
def badges():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM `Badge` WHERE `用户ID`=%s ORDER BY `获得时间` DESC",
                (session["uid"],))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "data": rows})


# ---------- 积分流水 ----------
@app.route("/api/points")
def points():
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT * FROM `PointsFlow` WHERE `用户ID`=%s "
        "ORDER BY `发生时间` DESC LIMIT 50", (session["uid"],))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "data": rows})


# ---------- 解除监督关系 ----------
@app.route("/api/supervise/<int:sup_id>", methods=["DELETE"])
def delete_supervise(sup_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "UPDATE `Supervise` SET `状态`='已解除' WHERE `监督ID`=%s AND `用户ID`=%s",
        (sup_id, session["uid"]))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"code": 0, "msg": "监督关系已解除"})


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
