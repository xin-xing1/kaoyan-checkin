# 考研备考监督打卡与激励管理系统（kaoyan_checkin）

围绕「计划—执行—监督—激励—反馈」备考闭环的 B/S 架构 Web 应用，前后端不分离，页面由 Flask 模板渲染，数据交互统一走 JSON 接口。

## 功能模块

| 模块 | 说明 |
| --- | --- |
| 用户注册与登录 | 手机号 + 密码，密码经 werkzeug 哈希存储，登录态存于 session |
| 考研目标管理 | 目标院校 / 专业 / 目标分数 / 备考阶段 / 起止日期 |
| 阶段计划管理 | 目标下拆解阶段计划，覆盖计划起止与阶段名称 |
| 每日任务管理 | 科目 / 预计时长 / 优先级 / 截止时间 / 完成状态 |
| 每日打卡 | 调用存储过程 `sp_checkin_and_award`，一次完成打卡写入、积分发放与任务状态更新 |
| 研友监督 | 按手机号建立监督关系，支持解除（状态置为已解除） |
| 积分与勋章 | 积分流水、勋章墙、全站积分排行（由视图统计） |

## 技术栈

- 后端：Flask + PyMySQL
- 数据库：MySQL 8.0（8 张表 / 3 个视图 / 2 个存储过程）
- 前端：Jinja2 模板 + 原生 HTML / CSS / JavaScript

## 目录结构

```
kaoyan-checkin/
├─ app.py                 # 路由、接口与业务逻辑
├─ config.py              # 数据库连接配置（首次运行需修改）
├─ requirements.txt       # 依赖清单
├─ sql/
│  └─ 数据库实现.sql       # 建库 + 建表 + 测试数据 + 视图 + 存储过程
├─ templates/             # base / index / login / goals / plans / tasks / checkin / supervise / rewards
├─ static/css/style.css   # 全局样式
└─ docs/                  # 需求分析、数据库设计、数据库实现文档
```

## 快速运行

1. 执行数据库脚本（会在 MySQL 中创建 `kaoyan_checkin` 库）
   ```bash
   mysql -u root -p < sql/数据库实现.sql
   ```
   脚本开头含 `DROP DATABASE IF EXISTS kaoyan_checkin`，重复执行会清空已有数据。

2. 修改 `config.py` 中的 `DB_CONFIG`，填入本机 MySQL 的账号密码
   ```python
   DB_CONFIG = {
       "host": "127.0.0.1",
       "user": "root",
       "password": "你的MySQL密码",
       "database": "kaoyan_checkin",
       "port": 3306,
   }
   ```

3. 安装依赖
   ```bash
   pip install -r requirements.txt
   ```

4. 启动服务，浏览器访问 http://127.0.0.1:5000
   ```bash
   python app.py
   ```

## 测试账号

种子数据中的 5 个用户统一密码为 `123456`，其中「赵六」为冻结账号，用于验证登录拦截。

## 主要接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | /api/register | 注册 |
| POST | /api/login | 登录 |
| GET | /api/logout | 退出登录 |
| GET / POST | /api/goals | 目标查询 / 新增 |
| DELETE | /api/goals/<id> | 删除目标 |
| GET / POST | /api/plans | 阶段计划查询 / 新增 |
| DELETE | /api/plans/<id> | 删除计划 |
| GET / POST | /api/tasks | 任务查询 / 新增 |
| PUT | /api/tasks/<id> | 更新任务完成状态 |
| POST | /api/checkin | 打卡（存储过程发放积分） |
| GET | /api/checkin | 打卡历史（近 50 条） |
| GET / POST | /api/supervise | 监督关系查询 / 建立 |
| DELETE | /api/supervise/<id> | 解除监督关系 |
| GET | /api/stats | 首页统计概览 |
| GET | /api/badges | 勋章列表 |
| GET | /api/points | 积分流水 |

接口统一返回 `{"code": 0, "data": ...}` 或 `{"code": 0, "msg": "..."}`。
