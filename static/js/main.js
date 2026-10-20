// 通用请求封装
async function api(url, method = "GET", body = null) {
    const opt = { method, headers: { "Content-Type": "application/json" } };
    if (body) opt.body = JSON.stringify(body);
    const res = await fetch(url, opt);
    return res.json();
}

function showMsg(text) {
    const el = document.getElementById("msg");
    if (el) { el.textContent = text; }
}

// ---------- 登录 / 注册 ----------
function switchTab(tab) {
    document.getElementById("loginForm").classList.toggle("hidden", tab !== "login");
    document.getElementById("regForm").classList.toggle("hidden", tab !== "register");
    document.getElementById("tabLogin").classList.toggle("active", tab === "login");
    document.getElementById("tabReg").classList.toggle("active", tab === "register");
}

document.addEventListener("DOMContentLoaded", () => {
    const loginForm = document.getElementById("loginForm");
    const regForm = document.getElementById("regForm");
    if (loginForm) loginForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        const data = await api("/api/login", "POST", {
            phone: document.getElementById("loginPhone").value,
            password: document.getElementById("loginPassword").value
        });
        if (data.code === 0) { location.href = "/"; }
        else showMsg(data.msg);
    });
    if (regForm) regForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        const data = await api("/api/register", "POST", {
            phone: document.getElementById("regPhone").value,
            nickname: document.getElementById("regNickname").value,
            password: document.getElementById("regPassword").value
        });
        if (data.code === 0) { showMsg("注册成功，请登录"); switchTab("login"); }
        else showMsg(data.msg);
    });

    loadStats();
});

async function loadStats() {
    const data = await api("/api/stats");
    if (data.code !== 0) return;
    const box = document.getElementById("statsBox");
    if (!box) return;
    box.innerHTML = `
        <div class="stat-card"><b>${data.checkin ? data.checkin["打卡次数"] : 0}</b>累计打卡</div>
        <div class="stat-card"><b>${data.rank ? data.rank["总积分"] : 0}</b>我的积分</div>
    `;
    const top = document.getElementById("topList");
    if (!top) return;
    top.innerHTML = "<li>🏆 全站积分榜 TOP10</li>" + (data.top10 || []).map((r, i) =>
        `<li>${i + 1}. ${r["昵称"]} — ${r["总积分"]} 分</li>`).join("");
}
