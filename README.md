---
AIGC:
    Label: "1"
    ContentProducer: 001191440300708461136T1XGW3
    ProduceID: 39961c867d0b8f297f9c671e540b1e13_c3b58c2bcc5111f1b307525400393706
    ReservedCode1: xtkBDzrNfQ4kOSuUWlBQU9wm248VEyL5uZ9UoBDPyTRT4G2JeBz1GLhS2th+d0frrxA0Vxi8WM/1hZCtqiC/6+C8eRHY6bCA7q8MIyHmm2AgrDRZh8mygPYuk+yDZrWptfjXsGtVFgx2y0DwrXvabcOdeZNG9ORY1vwCYoD6SIA4boI0Z4JV83iRgd0=
    ContentPropagator: 001191440300708461136T1XGW3
    PropagateID: 39961c867d0b8f297f9c671e540b1e13_c3b58c2bcc5111f1b307525400393706
    ReservedCode2: xtkBDzrNfQ4kOSuUWlBQU9wm248VEyL5uZ9UoBDPyTRT4G2JeBz1GLhS2th+d0frrxA0Vxi8WM/1hZCtqiC/6+C8eRHY6bCA7q8MIyHmm2AgrDRZh8mygPYuk+yDZrWptfjXsGtVFgx2y0DwrXvabcOdeZNG9ORY1vwCYoD6SIA4boI0Z4JV83iRgd0=
---

# 考研备考监督打卡与激励管理系统（kaoyan_checkin）

围绕「计划—执行—监督—激励—反馈」备考闭环的 B/S 架构 Web 应用。

## 功能模块

- 用户注册与登录（手机号 + 密码）
- 考研目标管理（院校 / 专业 / 分数 / 备考阶段）
- 每日任务管理（科目 / 优先级 / 截止时间）
- 每日打卡（调用存储过程自动发放积分）
- 研友监督（按手机号添加监督关系）
- 积分勋章与全站排行（视图统计）

## 技术栈

Flask + PyMySQL + MySQL 8.0 + HTML/CSS/JS

## 项目结构

- app.py             Flask 后端路由
- config.py          数据库配置
- sql/               建库脚本（8 表 + 测试数据 + 3 视图 + 2 存储过程）
- templates/         页面模板（base / login / index）
- static/            样式与脚本
- docs/              需求分析与数据库设计文档
- screenshots/       运行测试截图

## 快速运行

1. MySQL 中整体执行 `sql/数据库实现.sql` 初始化数据库
2. `pip install -r requirements.txt`
3. `python app.py`，浏览器访问 http://127.0.0.1:5000
*（内容由AI生成，仅供参考）*
