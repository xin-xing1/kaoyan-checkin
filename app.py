# -*- coding: utf-8 -*-
"""考研备考监督打卡与激励管理系统 —— Flask 后端"""
import pymysql
from flask import Flask, request, jsonify, render_template, session, redirect, url_for
from werkzeug.security import generate_password_hash, check_password_hash
from config import DB_CONFIG

app = Flask(__name__)
app.secret_key = "8f4c2b7e91d6a03f5e8b1c47d92a6f30e5b8c1d47a92f6e30b5c8d1a47e92f6b0"

# ---------- get_db ----------
def get_db():
    return pymysql.connect(
        host=DB_CONFIG["host"], user=DB_CONFIG["user"],
        password=DB_CONFIG["password"], database=DB_CONFIG["database"],
        charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor
    )


# ---------- 页面路由 ----------


# ---------- / ----------
@app.route("/")
def index():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("index.html", nickname=session.get("nickname"))


# ---------- /login ----------
@app.route("/login")
def login():
    return render_template("login.html")


# ---------- /goals ----------
@app.route("/goals")
def goals_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("goals.html", nickname=session.get("nickname"))


# ---------- /plans ----------
@app.route("/plans")
def plans_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("plans.html", nickname=session.get("nickname"))


# ---------- /tasks ----------
@app.route("/tasks")
def tasks_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("tasks.html", nickname=session.get("nickname"))


# ---------- /checkin ----------
@app.route("/checkin")
def checkin_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("checkin.html", nickname=session.get("nickname"))


# ---------- /supervise ----------
@app.route("/supervise")
def supervise_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("supervise.html", nickname=session.get("nickname"))


# ---------- /rewards ----------
@app.route("/rewards")
def rewards_page():
    if "uid" not in session:
        return redirect(url_for("login"))
    return render_template("rewards.html", nickname=session.get("nickname"))


# ---------- 用户注册与登录 ----------


# ---------- /api/register [POST] ----------
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


# ---------- /api/login [POST] ----------
@app.route("/api/login", methods=["POST"])
def login_api():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM `User` WHERE `手机号`=%s", (data["phone"],))
    user = cur.fetchone()
    cur.close()
    conn.close()
    if user and check_password_hash(user["密码"], data["password"]):
        session["uid"] = user["用户ID"]
        session["nickname"] = user["昵称"]
        return jsonify({"code": 0, "msg": "登录成功", "nickname": user["昵称"]})
    return jsonify({"code": 1, "msg": "手机号或密码错误"})


# ---------- /api/logout ----------
@app.route("/api/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


# ---------- 目标管理 ----------
