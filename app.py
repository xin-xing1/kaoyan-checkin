# -*- coding: utf-8 -*-
"""考研备考监督打卡与激励管理系统 —— Flask 后端"""
from flask import Flask, request, jsonify, render_template, session, redirect, url_for
app = Flask(__name__)
app.secret_key = "8f4c2b7e91d6a03f5e8b1c47d92a6f30e5b8c1d47a92f6e30b5c8d1a47e92f6b0"

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


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
