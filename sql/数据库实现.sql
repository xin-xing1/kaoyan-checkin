-- ============================================================================
-- 考研备考监督打卡与激励管理系统 —— 数据库实现脚本
-- 依据：《需求分析报告.docx》五、数据需求（12实体/7条主要关系/业务规则R1-R4）
--        《数据库设计-关系模式.docx》8个关系模式（User/Goal/Plan/Task/
--         Checkin/Supervise/PointsFlow/Badge）
-- 运行环境：MySQL 8.0（utf8mb4），建议使用 mysql 命令行或 Navicat 整体执行
-- 结构：①建库 -> ②建8表 -> ③测试数据 -> ④视图 -> ⑤存储过程
-- ============================================================================

-- ① 建库语句
DROP DATABASE IF EXISTS `kaoyan_checkin`;
CREATE DATABASE `kaoyan_checkin` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `kaoyan_checkin`;

-- ============================================================================
-- ② 建 8 张表（顺序按外键依赖：User -> Goal -> Plan -> Task -> Checkin/
--    Supervise/PointsFlow/Badge）
-- ============================================================================

-- 2.1 用户表 User（考研学生/研友/管理员；注册信息与个人资料）
CREATE TABLE `User` (
    `用户ID`     INT          NOT NULL AUTO_INCREMENT COMMENT '用户唯一标识，自增',
    `手机号`     VARCHAR(20)  NOT NULL COMMENT '注册手机号，短信验证码校验，展示时中间4位脱敏',
    `昵称`       VARCHAR(50)  NOT NULL COMMENT '昵称唯一性校验',
    `密码`       VARCHAR(100) NOT NULL COMMENT '8-20位含字母与数字，bcrypt加密存储',
    `头像`       VARCHAR(255)          DEFAULT NULL COMMENT '头像图片地址，可空',
    `备考阶段`   ENUM('基础','强化','冲刺') NOT NULL DEFAULT '基础' COMMENT '个人资料中的备考阶段',
    `目标公开范围` ENUM('公开','仅研友','私密') NOT NULL DEFAULT '仅研友' COMMENT '个人资料可见范围',
    `账号状态`   ENUM('正常','冻结') NOT NULL DEFAULT '正常' COMMENT '管理员可冻结/解冻异常账号',
    `注册时间`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间戳',
    PRIMARY KEY (`用户ID`),
    UNIQUE KEY `uk_user_phone` (`手机号`),
    UNIQUE KEY `uk_user_nickname` (`昵称`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 2.2 考研目标表 Goal（目标院校/专业/分数，指导阶段计划分解）
CREATE TABLE `Goal` (
    `目标ID`     INT         NOT NULL AUTO_INCREMENT COMMENT '考研目标唯一标识，自增',
    `用户ID`     INT         NOT NULL COMMENT '目标所属用户',
    `目标院校`   VARCHAR(100) NOT NULL COMMENT '必填',
    `目标专业`   VARCHAR(100) NOT NULL COMMENT '必填',
    `目标分数`   SMALLINT    NOT NULL COMMENT '必填，0-500整数',
    `备考阶段`   ENUM('基础','强化','冲刺') NOT NULL DEFAULT '基础' COMMENT '目标所处备考阶段',
    `开始日期`   DATE        NOT NULL COMMENT '目标开始日期',
    `结束日期`   DATE        NOT NULL COMMENT '目标结束日期',
    `状态`       ENUM('执行中','已完成') NOT NULL DEFAULT '执行中' COMMENT '执行中仅允许阶段内调整，完成阶段不可回退',
    PRIMARY KEY (`目标ID`),
    KEY `idx_goal_user` (`用户ID`),
    CONSTRAINT `fk_goal_user` FOREIGN KEY (`用户ID`) REFERENCES `User` (`用户ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考研目标表';

-- 2.3 阶段计划表 Plan（按基础/强化/冲刺阶段分解的计划）
CREATE TABLE `Plan` (
    `计划ID`   INT          NOT NULL AUTO_INCREMENT COMMENT '阶段计划唯一标识，自增',
    `目标ID`   INT          NOT NULL COMMENT '计划所属目标',
    `阶段`     ENUM('基础','强化','冲刺') NOT NULL DEFAULT '基础' COMMENT '计划对应阶段',
    `计划名称` VARCHAR(100) NOT NULL COMMENT '计划名称',
    `开始日期` DATE         NOT NULL COMMENT '计划开始日期',
    `结束日期` DATE         NOT NULL COMMENT '计划结束日期',
    PRIMARY KEY (`计划ID`),
    KEY `idx_plan_goal` (`目标ID`),
    CONSTRAINT `fk_plan_goal` FOREIGN KEY (`目标ID`) REFERENCES `Goal` (`目标ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='阶段计划表';

-- 2.4 每日任务表 Task（含科目与优先级，四态流转）
CREATE TABLE `Task` (
    `任务ID`   INT          NOT NULL AUTO_INCREMENT COMMENT '每日任务唯一标识，自增',
    `计划ID`   INT          NOT NULL COMMENT '任务所属计划',
    `任务名称` VARCHAR(100) NOT NULL COMMENT '必填，每日任务上限20条',
    `科目`     VARCHAR(50)  NOT NULL COMMENT '任务所属科目',
    `预计时长` INT          NOT NULL DEFAULT 60 COMMENT '预计学习时长（分钟）',
    `优先级`   ENUM('高','中','低') NOT NULL DEFAULT '中' COMMENT '任务优先级',
    `截止时间` DATETIME     NOT NULL COMMENT '任务截止时间',
    `完成状态` ENUM('待执行','进行中','已完成','已逾期') NOT NULL DEFAULT '待执行'
               COMMENT '四态流转；逾期任务标记红色并计入逾期率',
    PRIMARY KEY (`任务ID`),
    KEY `idx_task_plan` (`计划ID`),
    CONSTRAINT `fk_task_plan` FOREIGN KEY (`计划ID`) REFERENCES `Plan` (`计划ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='每日任务表';

-- 2.5 打卡记录表 Checkin（打卡凭证，可追溯不可篡改）
CREATE TABLE `Checkin` (
    `打卡ID`     INT          NOT NULL AUTO_INCREMENT COMMENT '打卡记录唯一标识，自增',
    `任务ID`     INT          NOT NULL COMMENT '打卡对应任务',
    `用户ID`     INT          NOT NULL COMMENT '打卡用户',
    `完成时间`   DATETIME     NOT NULL COMMENT '任务完成时间（精确到秒）',
    `打卡时间戳` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '点击打卡的时间戳，可追溯不可篡改',
    `图片证明URL` VARCHAR(255) DEFAULT NULL COMMENT '图片打卡上传证明，可空',
    PRIMARY KEY (`打卡ID`),
    KEY `idx_checkin_task` (`任务ID`),
    KEY `idx_checkin_user` (`用户ID`),
    CONSTRAINT `fk_checkin_task` FOREIGN KEY (`任务ID`) REFERENCES `Task` (`任务ID`),
    CONSTRAINT `fk_checkin_user` FOREIGN KEY (`用户ID`) REFERENCES `User` (`用户ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='打卡记录表';

-- 2.6 监督关系表 Supervise（用户与研友互督，N:M 关系通过本实体实现）
CREATE TABLE `Supervise` (
    `监督ID`   INT          NOT NULL AUTO_INCREMENT COMMENT '监督关系唯一标识，自增',
    `用户ID`   INT          NOT NULL COMMENT '被监督用户',
    `研友ID`   INT          NOT NULL COMMENT '监督研友',
    `建立时间` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '监督关系建立时间',
    `状态`     ENUM('有效','已解除') NOT NULL DEFAULT '有效'
               COMMENT '每人最多10个监督关系；任一成员可解除，连续7天未打卡自动移出',
    PRIMARY KEY (`监督ID`),
    KEY `idx_sup_user` (`用户ID`),
    KEY `idx_sup_friend` (`研友ID`),
    CONSTRAINT `fk_sup_user`   FOREIGN KEY (`用户ID`) REFERENCES `User` (`用户ID`),
    CONSTRAINT `fk_sup_friend` FOREIGN KEY (`研友ID`) REFERENCES `User` (`用户ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监督关系表';

-- 2.7 积分流水表 PointsFlow（积分实时入账，支撑每日排行）
CREATE TABLE `PointsFlow` (
    `流水ID`   INT          NOT NULL AUTO_INCREMENT COMMENT '积分流水唯一标识，自增',
    `用户ID`   INT          NOT NULL COMMENT '积分所属用户',
    `分值`     INT          NOT NULL COMMENT '+10正常打卡/+3补卡通过/+5提前完成等',
    `积分类型` VARCHAR(20)  NOT NULL COMMENT '打卡/补卡/提前完成/请假等',
    `发生时间` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '积分实时入账时间，每日24:00汇总排行',
    PRIMARY KEY (`流水ID`),
    KEY `idx_points_user` (`用户ID`),
    CONSTRAINT `fk_points_user` FOREIGN KEY (`用户ID`) REFERENCES `User` (`用户ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='积分流水表';

-- 2.8 勋章记录表 Badge（成就勋章，记录不可撤销）
CREATE TABLE `Badge` (
    `勋章ID`   INT          NOT NULL AUTO_INCREMENT COMMENT '勋章记录唯一标识，自增',
    `用户ID`   INT          NOT NULL COMMENT '勋章所属用户',
    `勋章类型` VARCHAR(50)  NOT NULL COMMENT '连续打卡7/14/30天、早起学习、任务完成、全勤月',
    `获得时间` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '勋章获得时间，记录不可撤销',
    PRIMARY KEY (`勋章ID`),
    KEY `idx_badge_user` (`用户ID`),
    CONSTRAINT `fk_badge_user` FOREIGN KEY (`用户ID`) REFERENCES `User` (`用户ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='勋章记录表';

-- ============================================================================
-- ③ 测试数据（覆盖用户/目标/计划/任务/打卡/监督/积分/勋章）
-- ============================================================================
-- 用户
INSERT INTO `User` (`手机号`,`昵称`,`密码`,`头像`,`备考阶段`,`目标公开范围`,`账号状态`,`注册时间`) VALUES
('13800000001','张三','$2b$10$demoHashAaaa','head_a.png','强化','仅研友','正常','2026-09-20 08:00:00'),
('13800000002','李四','$2b$10$demoHashBbbb','head_b.png','基础','公开','正常','2026-09-21 09:30:00'),
('13800000003','王五','$2b$10$demoHashCccc',NULL,'基础','私密','正常','2026-09-22 10:00:00'),
('13800000004','赵六','$2b$10$demoHashDddd','head_d.png','冲刺','仅研友','冻结','2026-09-23 11:00:00'),
('13800000005','钱七','$2b$10$demoHashEeee',NULL,'强化','公开','正常','2026-09-24 12:00:00');

-- 考研目标
INSERT INTO `Goal` (`用户ID`,`目标院校`,`目标专业`,`目标分数`,`备考阶段`,`开始日期`,`结束日期`,`状态`) VALUES
(1,'浙江大学','计算机技术',380,'强化','2026-09-01','2027-12-20','执行中'),
(2,'电子科技大学','电子信息',360,'基础','2026-10-01','2027-12-20','执行中'),
(3,'武汉大学','软件工程',370,'基础','2026-10-05','2027-12-20','执行中');

-- 阶段计划
INSERT INTO `Plan` (`目标ID`,`阶段`,`计划名称`,`开始日期`,`结束日期`) VALUES
(1,'强化','强化阶段-数学专项计划','2026-10-01','2026-12-31'),
(1,'强化','强化阶段-英语专项计划','2026-10-01','2026-12-31'),
(2,'基础','基础阶段-专业课计划','2026-10-01','2027-01-31'),
(3,'基础','基础阶段-公共课计划','2026-10-05','2027-01-31');

-- 每日任务
INSERT INTO `Task` (`计划ID`,`任务名称`,`科目`,`预计时长`,`优先级`,`截止时间`,`完成状态`) VALUES
(1,'线代第4章课后习题','数学',120,'高','2026-10-08 23:59:59','已完成'),
(1,'高数真题2篇','数学',90,'中','2026-10-09 23:59:59','已完成'),
(1,'线代第5章矩阵复习','数学',100,'高','2026-10-10 23:59:59','已完成'),
(2,'英语真题阅读2篇','英语',60,'中','2026-10-08 23:59:59','已完成'),
(2,'考研英语单词150个','英语',40,'低','2026-10-09 23:59:59','已完成'),
(3,'操作系统第3章','专业课',150,'高','2026-10-08 23:59:59','已完成'),
(3,'数据结构栈队列','专业课',120,'中','2026-10-09 23:59:59','进行中'),
(4,'马原30页','政治',60,'低','2026-10-09 23:59:59','待执行');

-- 打卡记录
INSERT INTO `Checkin` (`任务ID`,`用户ID`,`完成时间`,`打卡时间戳`,`图片证明URL`) VALUES
(1,1,'2026-10-08 20:30:00','2026-10-08 20:31:05','https://cdn.example.com/checkin/1.jpg'),
(2,1,'2026-10-09 21:00:00','2026-10-09 21:02:11',NULL),
(3,1,'2026-10-10 20:45:00','2026-10-10 20:46:02','https://cdn.example.com/checkin/3.jpg'),
(4,1,'2026-10-08 22:10:00','2026-10-08 22:12:33',NULL),
(5,1,'2026-10-09 22:00:00','2026-10-09 22:01:40',NULL),
(6,2,'2026-10-08 21:30:00','2026-10-08 21:31:55','https://cdn.example.com/checkin/6.jpg'),
(7,2,'2026-10-09 21:20:00','2026-10-09 21:22:09',NULL);

-- 监督关系
INSERT INTO `Supervise` (`用户ID`,`研友ID`,`建立时间`,`状态`) VALUES
(1,2,'2026-09-25 15:00:00','有效'),
(2,1,'2026-09-25 15:00:00','有效'),
(2,3,'2026-09-26 16:30:00','有效'),
(1,5,'2026-09-27 09:00:00','已解除');

-- 积分流水
INSERT INTO `PointsFlow` (`用户ID`,`分值`,`积分类型`,`发生时间`) VALUES
(1,10,'正常打卡','2026-10-08 20:31:05'),
(1,5,'提前完成','2026-10-08 20:31:05'),
(1,10,'正常打卡','2026-10-09 21:02:11'),
(1,10,'正常打卡','2026-10-10 20:46:02'),
(1,10,'正常打卡','2026-10-08 22:12:33'),
(1,10,'正常打卡','2026-10-09 22:01:40'),
(2,10,'正常打卡','2026-10-08 21:31:55'),
(2,10,'正常打卡','2026-10-09 21:22:09'),
(2,3,'补卡通过','2026-10-10 08:00:00'),
(3,10,'正常打卡','2026-10-08 20:00:00');

-- 勋章记录
INSERT INTO `Badge` (`用户ID`,`勋章类型`,`获得时间`) VALUES
(1,'连续打卡7天','2026-10-07 08:00:00'),
(1,'早起学习','2026-10-08 06:50:00'),
(2,'连续打卡7天','2026-10-07 08:00:00'),
(3,'任务完成','2026-10-08 22:00:00');

-- ============================================================================
-- ④ 视图（功能贴合系统业务）
-- ============================================================================

-- 4.1 用户打卡统计视图：按用户聚合打卡次数/打卡天数/最近打卡时间，支撑学习数据统计模块
CREATE OR REPLACE VIEW `v_user_checkin_stats` AS
SELECT
    u.`用户ID`,
    u.`昵称`,
    COUNT(c.`打卡ID`)                   AS `打卡次数`,
    COUNT(DISTINCT DATE(c.`打卡时间戳`)) AS `打卡天数`,
    MAX(c.`打卡时间戳`)                 AS `最近打卡时间`
FROM `User` u
LEFT JOIN `Checkin` c ON u.`用户ID` = c.`用户ID`
GROUP BY u.`用户ID`, u.`昵称`;

-- 4.2 积分排行视图：按用户汇总总积分，支撑个人/小组/全站排行（每日24:00汇总口径）
CREATE OR REPLACE VIEW `v_points_rank` AS
SELECT
    u.`用户ID`,
    u.`昵称`,
    COALESCE(SUM(p.`分值`), 0) AS `总积分`,
    COUNT(p.`流水ID`)          AS `积分流水条数`
FROM `User` u
LEFT JOIN `PointsFlow` p ON u.`用户ID` = p.`用户ID`
GROUP BY u.`用户ID`, u.`昵称`
ORDER BY `总积分` DESC;

-- 4.3 任务完成统计视图：按用户统计任务总数/已完成数/完成率，支撑任务完成率与逾期率分析
CREATE OR REPLACE VIEW `v_task_completion_stats` AS
SELECT
    u.`用户ID`,
    u.`昵称`,
    COUNT(t.`任务ID`) AS `任务总数`,
    SUM(CASE WHEN t.`完成状态` = '已完成' THEN 1 ELSE 0 END) AS `已完成数`,
    ROUND(SUM(CASE WHEN t.`完成状态` = '已完成' THEN 1 ELSE 0 END) / COUNT(t.`任务ID`) * 100, 2) AS `完成率(%)`
FROM `User` u
LEFT JOIN `Goal` g  ON u.`用户ID` = g.`用户ID`
LEFT JOIN `Plan` p  ON g.`目标ID` = p.`目标ID`
LEFT JOIN `Task` t  ON p.`计划ID` = t.`计划ID`
GROUP BY u.`用户ID`, u.`昵称`;

-- ============================================================================
-- ⑤ 存储过程（含 DELIMITER 语法）
-- ============================================================================

-- 5.1 打卡积分自动入账：插入打卡记录 -> 发放积分 -> 更新任务完成状态
--     对应业务规则：正常打卡 10 分/项、任务提前完成额外 5 分（此处按基础分值 10 发放）
DELIMITER $$
CREATE PROCEDURE `sp_checkin_and_award`(
    IN  p_user_id       INT,          -- 打卡用户ID
    IN  p_task_id       INT,          -- 打卡任务ID
    IN  p_complete_time DATETIME,     -- 任务完成时间（精确到秒）
    IN  p_image_url     VARCHAR(255), -- 图片证明URL，可空
    OUT p_checkin_id    INT           -- 新生成的打卡ID
)
BEGIN
    -- 任务存在性校验（仅处理已登记任务）
    IF NOT EXISTS (SELECT 1 FROM `Task` WHERE `任务ID` = p_task_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务不存在，无法打卡';
    END IF;

    -- ① 插入打卡记录
    INSERT INTO `Checkin` (`任务ID`, `用户ID`, `完成时间`, `图片证明URL`)
    VALUES (p_task_id, p_user_id, p_complete_time, p_image_url);
    SET p_checkin_id = LAST_INSERT_ID();

    -- ② 发放积分：正常打卡 10 分/项（对应 R1 规则与 FR-05 积分规则）
    INSERT INTO `PointsFlow` (`用户ID`, `分值`, `积分类型`, `发生时间`)
    VALUES (p_user_id, 10, '正常打卡', NOW());

    -- ③ 更新任务完成状态为“已完成”
    UPDATE `Task` SET `完成状态` = '已完成' WHERE `任务ID` = p_task_id;
END$$
DELIMITER ;

-- 5.2 用户学习统计汇总：按时间段输出打卡次数/打卡天数/获得积分，支撑数据统计反馈流程
DELIMITER $$
CREATE PROCEDURE `sp_user_checkin_summary`(
    IN  p_user_id INT, -- 统计用户ID
    IN  p_begin   DATE, -- 统计开始日期（含）
    IN  p_end     DATE  -- 统计结束日期（含）
)
BEGIN
    -- ① 打卡概况
    SELECT
        COUNT(c.`打卡ID`)                   AS `打卡次数`,
        COUNT(DISTINCT DATE(c.`打卡时间戳`)) AS `打卡天数`,
        MAX(c.`打卡时间戳`)                 AS `最近打卡时间`
    FROM `Checkin` c
    WHERE c.`用户ID` = p_user_id
      AND DATE(c.`打卡时间戳`) BETWEEN p_begin AND p_end;

    -- ② 积分汇总（含积分类型明细）
    SELECT `积分类型`, SUM(`分值`) AS `类型小计`, COUNT(*) AS `流水条数`
    FROM `PointsFlow`
    WHERE `用户ID` = p_user_id
      AND DATE(`发生时间`) BETWEEN p_begin AND p_end
    GROUP BY `积分类型`;
END$$
DELIMITER ;

-- ============================================================================
-- ⑥ 存储过程调用示例（取消注释即可执行验证）
-- ============================================================================
-- CALL sp_checkin_and_award(1, 3, '2026-10-11 20:30:00', 'https://cdn.example.com/checkin/11.jpg', @cid);
-- SELECT @cid AS 新打卡ID;
-- CALL sp_user_checkin_summary(1, '2026-10-01', '2026-10-13');

-- 视图查询示例
-- SELECT * FROM v_user_checkin_stats;
-- SELECT * FROM v_points_rank;
-- SELECT * FROM v_task_completion_stats;
