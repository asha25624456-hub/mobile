<?php
header('Content-Type: text/html; charset=UTF-8');

$backendUrl = '../backend';
$uploadsUrl = 'https://std.mcs.psu.ac.th/6620310027/html/apinew/uploads';
$pageRoutes = [
    'index.php' => 'overview',
    'requisitions.php' => 'requisitions',
    'products.php' => 'products',
    'transactions.php' => 'transactions',
    'notifications.php' => 'notifications',
    'security.php' => 'security',
];
$initialPage = $pageRoutes[basename($_SERVER['SCRIPT_NAME'] ?? 'index.php')] ?? 'overview';
?>

<!doctype html>
<html lang="th">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>คลังพัสดุ | Admin</title>
    <link rel="stylesheet" href="dashboard.css">

    <link rel="stylesheet" href="style.css">
</head>

<body>

    <!-- =========================
         Login View
    ========================= -->

    <div id="loginView" class="login hidden">
        <form id="loginForm">

            <h1>เข้าสู่ระบบผู้ดูแล</h1>

            <div class="muted">
                ระบบจัดการคลังพัสดุ
            </div>

            <div id="loginError" class="notice"></div>

            <label for="username">
                ชื่อผู้ใช้
            </label>

            <input
                id="username"
                name="username"
                autocomplete="username"
                required>

            <label for="password">
                รหัสผ่าน
            </label>

            <input
                id="password"
                name="password"
                type="password"
                autocomplete="current-password"
                required>

            <button class="primary">
                เข้าสู่ระบบ
            </button>

        </form>
    </div>

    <!-- =========================
         Application View
    ========================= -->

    <div id="appView" class="shell hidden">

        <!-- Sidebar -->
        <aside class="side">

            <div class="brand">
                คลังพัสดุ · ADMIN
            </div>

            <nav class="nav">
                <button data-page="overview" data-href="index.php" class="<?= $initialPage === 'overview' ? 'active' : '' ?>">
                    ภาพรวม
                </button>

                <button data-page="requisitions" data-href="requisitions.php" class="<?= $initialPage === 'requisitions' ? 'active' : '' ?>">
                    รายการเบิก
                </button>

                <button data-page="products" data-href="products.php" class="<?= $initialPage === 'products' ? 'active' : '' ?>">
                    สินค้าและวัสดุ
                </button>

                <button data-page="transactions" data-href="transactions.php" class="<?= $initialPage === 'transactions' ? 'active' : '' ?>">
                    ประวัติคลัง
                </button>

                <button data-page="notifications" data-href="notifications.php" class="<?= $initialPage === 'notifications' ? 'active' : '' ?>">
                    การแจ้งเตือน
                </button>

                <button data-page="security" data-href="security.php" class="<?= $initialPage === 'security' ? 'active' : '' ?>">
                    เปลี่ยนรหัสผ่าน
                </button>
            </nav>

        </aside>

        <!-- Main -->
        <main class="main">

            <header class="top">

                <strong id="pageHeading">
                    ภาพรวม
                </strong>

                <div>
                    <span id="adminName"></span>

                    <button
                        id="logout"
                        class="btn secondary">
                        ออกจากระบบ
                    </button>
                </div>

            </header>

            <section class="content">

                <h1
                    class="title"
                    id="pageTitle">
                    ภาพรวม
                </h1>

                <div
                    class="muted"
                    id="pageDescription">
                    ข้อมูลการเบิกและคลังวัสดุ
                </div>

                <div id="pageBody"></div>

            </section>

        </main>

    </div>

    <script src="dashboard.js"></script>
    <script>
        const API = <?= json_encode(
                        $backendUrl,
                        JSON_UNESCAPED_SLASHES
                    ) ?>;

        const UPLOADS = <?= json_encode(
                            $uploadsUrl,
                            JSON_UNESCAPED_SLASHES
                        ) ?>;
        const INITIAL_PAGE = <?= json_encode($initialPage) ?>;

        let token =
            sessionStorage.getItem('admin_token') || '';

        let currentAdmin =
            JSON.parse(
                sessionStorage.getItem('admin_profile') || 'null'
            );

        const $ = (selector) =>
            document.querySelector(selector);

        const esc = (value) =>
            String(value ?? '').replace(
                /[&<>"']/g,
                (char) => ({
                    '&': '&amp;',
                    '<': '&lt;',
                    '>': '&gt;',
                    '"': '&quot;',
                    "'": '&#39;'
                } [char])
            );

        // ส่วน: เชื่อมต่อ API backend

        async function api(path, data = {}) {
            const body = new URLSearchParams(data);

            const res = await fetch(
                `${API}/${path}.php`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    body
                }
            );

            const json = await res.json();

            if (
                !res.ok ||
                json.status !== 'success'
            ) {
                throw new Error(
                    json.message ||
                    'ทำรายการไม่สำเร็จ'
                );
            }

            return json;
        }

        // ส่วน: เข้าสู่ระบบและออกจากระบบ

        function setSignedIn(signedIn) {
            $('#loginView')
                .classList
                .toggle('hidden', signedIn);

            $('#appView')
                .classList
                .toggle('hidden', !signedIn);
        }

        function showError(error) {
            alert(
                error.message ||
                String(error)
            );
        }

        $('#loginForm').addEventListener(
            'submit',
            async (event) => {
                event.preventDefault();

                $('#loginError').textContent = '';

                try {
                    const result = await api(
                        'auth/login_admin', {
                            username: $('#username')
                                .value
                                .trim(),

                            password: $('#password').value
                        }
                    );

                    token = result.token;
                    currentAdmin = result.admin;

                    sessionStorage.setItem(
                        'admin_token',
                        token
                    );

                    sessionStorage.setItem(
                        'admin_profile',
                        JSON.stringify(currentAdmin)
                    );

                    setSignedIn(true);

                    $('#adminName').textContent =
                        currentAdmin.name ||
                        currentAdmin.username;

                    loadPage(INITIAL_PAGE);

                } catch (error) {
                    $('#loginError').textContent =
                        error.message;
                }
            }
        );

        $('#logout').addEventListener(
            'click',
            async () => {
                try {
                    await api('auth/logout_admin');
                } catch (_) {}

                sessionStorage.clear();
                token = '';

                setSignedIn(false);
            }
        );

        // ส่วน: เมนูเปลี่ยนหน้า

        document
            .querySelectorAll('.nav button')
            .forEach((button) => {
                button.addEventListener(
                    'click',
                    () => {
                        document
                            .querySelectorAll(
                                '.nav button'
                            )
                            .forEach((item) => {
                                item.classList.toggle(
                                    'active',
                                    item === button
                                );
                            });

                        window.location.href = button.dataset.href;
                    }
                );
            });

        function heading(title, description) {
            $('#pageHeading').textContent = title;
            $('#pageTitle').textContent = title;
            $('#pageDescription').textContent =
                description;
        }

        const table = (heads, rows) => `
            <div class="panel table-wrap">
                <table>
                    <thead>
                        <tr>
                            ${heads
                                .map(
                                    (head) =>
                                        `<th>${head}</th>`
                                )
                                .join('')}
                        </tr>
                    </thead>

                    <tbody>
                        ${
                            rows ||
                            `
                                <tr>
                                    <td
                                        colspan="${heads.length}"
                                        class="empty"
                                    >
                                        ไม่พบข้อมูล
                                    </td>
                                </tr>
                            `
                        }
                    </tbody>
                </table>
            </div>
        `;


        const statusText = {

            PENDING: 'รออนุมัติ',
            APPROVED: 'อนุมัติแล้ว',
            ISSUED: 'เบิกแล้ว',
            REJECTED: 'ปฏิเสธ',
            CANCELLED: 'ยกเลิก',

            PICKING: 'กำลังจัดของ',
            PICKED: 'จัดของแล้ว',

            READY: 'พร้อมรับ',
            PICKED_UP: 'รับของแล้ว',

            ACTIVE: 'ใช้งาน',
            INACTIVE: 'ปิดใช้งาน',
            SUSPENDED: 'ระงับ',

            LOW_STOCK: 'ใกล้หมด',
            OUT_OF_STOCK: 'หมดสต็อก',

            IN: 'รับเข้า',
            OUT: 'จ่ายออก',
            ADJUSTMENT: 'ปรับยอด'
        };

        const referenceText = {
            requisition: 'ใบเบิกพัสดุ',
            pickup: 'การรับของ',
            manual: 'บันทึกโดยผู้ดูแล',
            initial: 'ยอดยกมา',
            adjustment: 'ปรับปรุงยอด',
            product: 'พัสดุ'
        };

        const refLabel = (value) =>
            referenceText[String(value ?? '').toLowerCase()] ||
            value ||
            '-';

        const badge = (status) => `
            <span class="status ${esc(status)}">
                ${esc(statusText[status] || status || '-')}
            </span>
        `;

        const stockStatus = (item) =>
            item.status === 'INACTIVE' ?
            'INACTIVE' :
            Number(item.available_quantity) <= 0 ?
            'OUT_OF_STOCK' :
            Number(item.available_quantity) <
            Number(item.minimum_stock) ?
            'LOW_STOCK' :
            'ACTIVE';

        const parseDate = (value) => {
            if (!value) return null;
            const d = new Date(String(value).replace(' ', 'T'));
            return isNaN(d) ? null : d;
        };

        const fmtDate = (value) => {
            const d = parseDate(value);
            return d ?
                d.toLocaleDateString('th-TH', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric'
                }) :
                '-';
        };

        const fmtDateTime = (value) => {
            const d = parseDate(value);
            return d ?
                d.toLocaleString('th-TH', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }) + ' น.' :
                '-';
        };

        const fmtNum = (value) =>
            value === null || value === undefined || value === '' ||
            !Number.isFinite(Number(value)) ?
            '-' :
            Number(value).toLocaleString('th-TH');

        // ส่วน: รูปสินค้า (ชื่อวัสดุ -> ชื่อไฟล์ในโฟลเดอร์ uploads)
        const productImageFiles = {
            'ดินสอไม้ HB': 'pencil-hb.jpg',
            'กล่องเก็บเอกสารพลาสติก': 'plastic-document-box.jpg',
            'กล่องแฟ้มเอกสาร': 'document-file-box.jpg',
            'ลูกฟุตบอล': 'football.jpg',
            'กล่องเอกสารขนาด A4': 'a4-document-box.jpg'
        };

        const normalizeName = (value) =>
            String(value ?? '').replace(/\s+/g, ' ').trim().toLowerCase();

        const productImageIndex = Object.fromEntries(
            Object.entries(productImageFiles).map(
                ([name, file]) => [normalizeName(name), file]
            )
        );

        // ลำดับการหารูป: image_url จากฐานข้อมูล -> จับคู่จากชื่อสินค้า -> ไม่มีรูป
        function productImageUrl(item) {
            const raw = String(
                item?.image_url || item?.product_image || ''
            ).trim();

            if (raw) {
                if (/^(https?:)?\/\//i.test(raw) || raw.startsWith('/')) {
                    return raw;
                }
                return `${UPLOADS}/${raw.replace(/^\.?\/?(uploads\/)?/, '')}`;
            }

            const file = productImageIndex[normalizeName(item?.product_name)];
            return file ? `${UPLOADS}/${encodeURIComponent(file)}` : '';
        }

        // รูปย่อ: ถ้าไม่มีรูปหรือโหลดไม่ได้ จะแสดงตัวอักษรแรกของชื่อแทน
        function productThumb(item, size = 'sm') {
            const url = productImageUrl(item);
            const initial = String(item?.product_name || '?')
                .trim().charAt(0).toUpperCase();

            return `
                <span class="product-thumb ${size}">
                    <b>${esc(initial)}</b>
                    ${url ? `<img src="${esc(url)}"
                        alt="${esc(item?.product_name || '')}"
                        loading="lazy"
                        onerror="this.remove()">` : ''}
                </span>
            `;
        }

        async function loadPage(page) {
            try {
                if (page === 'overview') {
                    return await overview();
                }

                if (page === 'requisitions') {
                    return await requisitions();
                }

                if (page === 'products') {
                    return await products();
                }

                if (page === 'transactions') {
                    return await transactions();
                }

                if (page === 'notifications') {
                    return await notifications();
                }

                if (page === 'security') {
                    return security();
                }

            } catch (error) {
                showError(error);

                if (
                    /session|เข้าสู่ระบบ|หมดอายุ/i
                    .test(error.message)
                ) {
                    sessionStorage.clear();
                    token = '';
                    setSignedIn(false);
                }
            }
        }

        // หน้า: ภาพรวม Dashboard
        async function overview() {
            heading(
                'ภาพรวม',
                'ภาพรวมการเบิกจ่าย คลังสินค้า และสถานะงานแบบเรียลไทม์จากข้อมูลระบบ'
            );

            const [
                productsResult,
                requisitionsResult,
                transactionsResult
            ] = await Promise.all([
                api('admin/read_products'),
                api('admin/read_requisitions'),
                api('admin/read_inventory_transactions')
            ]);

            const products = productsResult.data || [];
            const requisitions = requisitionsResult.data || [];
            const transactions = transactionsResult.data || [];
            const now = new Date();

            const outTransactions = transactions.filter(
                item => String(item.transaction_type || '').toUpperCase() === 'OUT'
            );

            const periodStats = (rows, period) => {
                const filtered = rows.filter(item => {
                    const date = parseDate(item.created_at);
                    if (!date) return false;

                    if (period === 'day') {
                        return date.toDateString() === now.toDateString();
                    }

                    if (period === 'month') {
                        return date.getFullYear() === now.getFullYear() &&
                            date.getMonth() === now.getMonth();
                    }

                    return date.getFullYear() === now.getFullYear();
                });

                return {
                    items: filtered.length,
                    quantity: filtered.reduce(
                        (sum, item) => sum + Number(item.quantity || 0),
                        0
                    )
                };
            };

            const daily = periodStats(outTransactions, 'day');
            const monthly = periodStats(outTransactions, 'month');
            const yearly = periodStats(outTransactions, 'year');
            const pending = requisitions.filter(item => item.status === 'PENDING').length;
            const approved = requisitions.filter(item => item.status === 'APPROVED').length;
            const rejected = requisitions.filter(item => item.status === 'REJECTED').length;
            const completed = requisitions.filter(item => ['PICKED', 'PICKED_UP', 'ISSUED'].includes(item.status) ||
                item.pickup_status === 'PICKED'
            ).length;
            const low = products.filter(item =>
                Number(item.available_quantity) < Number(item.minimum_stock)
            ).length;

            const topBorrowed = Object.values(
                outTransactions.reduce((acc, item) => {
                    const key = item.product_name || 'ไม่ระบุสินค้า';
                    if (!acc[key]) {
                        acc[key] = {
                            product_name: key,
                            quantity: 0,
                            transactions: 0
                        };
                    }
                    acc[key].quantity += Number(item.quantity || 0);
                    acc[key].transactions += 1;
                    return acc;
                }, {})
            ).sort((a, b) => b.quantity - a.quantity).slice(0, 5);

            // เตรียมข้อมูลกราฟย้อนหลัง 12 เดือนจากรายการจ่ายออกจริง
            const monthlyChart = [];
            for (let i = 11; i >= 0; i--) {
                const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
                const year = d.getFullYear();
                const month = d.getMonth();
                const rows = outTransactions.filter(item => {
                    const date = parseDate(item.created_at);
                    return date && date.getFullYear() === year && date.getMonth() === month;
                });
                monthlyChart.push({
                    label: d.toLocaleDateString('th-TH', {
                        month: 'short',
                        year: '2-digit'
                    }),
                    quantity: rows.reduce((sum, item) => sum + Number(item.quantity || 0), 0),
                    transactions: rows.length
                });
            }

            const dashboardData = {
                monthlyChart,
                topBorrowed,
                statusChart: [{
                        label: 'รออนุมัติ',
                        value: pending
                    },
                    {
                        label: 'อนุมัติแล้ว',
                        value: approved
                    },
                    {
                        label: 'รับแล้ว',
                        value: completed
                    },
                    {
                        label: 'ปฏิเสธ',
                        value: rejected
                    }
                ].filter(item => item.value > 0)
            };

            $('#pageBody').innerHTML = `
                <div class="dashboard-hero">
                    <div>
                        <div class="eyebrow">INVENTORY OVERVIEW</div>
                        <h2>ศูนย์ควบคุมคลังพัสดุ</h2>
                        <p>ติดตามการเบิกจ่าย สินค้าที่มีการใช้งานสูง และสถานะคำขอได้จากหน้าเดียว</p>
                    </div>
                    <div class="dashboard-date">
                        <span>ข้อมูล ณ</span>
                        <strong>${esc(now.toLocaleDateString('th-TH', {
                            weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
                        }))}</strong>
                    </div>
                </div>

                <div class="dashboard-stat-grid">
                    <div class="dashboard-stat blue">
                        <div class="stat-icon">↗</div>
                        <div><span>เบิกวันนี้</span><strong>${fmtNum(daily.quantity)}</strong><small>${fmtNum(daily.items)} รายการ</small></div>
                    </div>
                    <div class="dashboard-stat purple">
                        <div class="stat-icon">◷</div>
                        <div><span>เบิกเดือนนี้</span><strong>${fmtNum(monthly.quantity)}</strong><small>${fmtNum(monthly.items)} รายการ</small></div>
                    </div>
                    <div class="dashboard-stat green">
                        <div class="stat-icon">▣</div>
                        <div><span>เบิกปีนี้</span><strong>${fmtNum(yearly.quantity)}</strong><small>${fmtNum(yearly.items)} รายการ</small></div>
                    </div>
                    <div class="dashboard-stat orange">
                        <div class="stat-icon">!</div>
                        <div><span>รออนุมัติ</span><strong>${fmtNum(pending)}</strong><small>สินค้าใกล้หมด ${fmtNum(low)} รายการ</small></div>
                    </div>
                </div>

                <div class="dashboard-chart-grid">
                    <section class="dashboard-panel dashboard-chart-wide">
                        <div class="panel-head">
                            <div><h3>แนวโน้มการเบิกจ่าย</h3><p>จำนวนหน่วยที่จ่ายออกย้อนหลัง 12 เดือน</p></div>
                            <span class="panel-tag">OUT / 12 เดือน</span>
                        </div>
                        <div class="chart-wrap line-chart-wrap"><canvas id="monthlyUsageChart"></canvas></div>
                    </section>

                    <section class="dashboard-panel">
                        <div class="panel-head">
                            <div><h3>สถานะรายการเบิก</h3><p>ภาพรวมคำขอทั้งหมด</p></div>
                        </div>
                        <div class="chart-wrap donut-chart-wrap"><canvas id="requestStatusChart"></canvas></div>
                    </section>

                    <section class="dashboard-panel dashboard-chart-wide">
                        <div class="panel-head">
                            <div><h3>สินค้าที่เบิกมากที่สุด</h3><p>จัดอันดับตามจำนวนหน่วยที่จ่ายออก</p></div>
                            <span class="panel-tag">TOP 5</span>
                        </div>
                        <div class="chart-wrap bar-chart-wrap"><canvas id="topBorrowedChart"></canvas></div>
                    </section>

                    <section class="dashboard-panel">
                        <div class="panel-head"><div><h3>สรุปคลัง</h3><p>สถานะข้อมูลปัจจุบัน</p></div></div>
                        <div class="dashboard-summary-list">
                            <div><span>สินค้าทั้งหมด</span><strong>${fmtNum(products.length)}</strong></div>
                            <div><span>รายการเบิกทั้งหมด</span><strong>${fmtNum(requisitions.length)}</strong></div>
                            <div><span>รออนุมัติ</span><strong class="text-orange">${fmtNum(pending)}</strong></div>
                            <div><span>สินค้าใกล้หมด</span><strong class="text-red">${fmtNum(low)}</strong></div>
                        </div>
                    </section>
                </div>

                <div class="dashboard-section-title">
                    <div><h3>รายการเบิกล่าสุด</h3><p>รายการล่าสุดจากระบบ</p></div>
                </div>
                ${requestTable(requisitions.slice(0, 8))}
            `;

            window.renderInventoryDashboardCharts?.(dashboardData);
        }

        // ตาราง: รายการเบิกและปุ่มดำเนินการ
        function requestTable(rows, allowManage = false) {
            return table(
                [
                    'เลขที่',
                    'ผู้เบิก',
                    'วันที่ต้องการ',
                    'สถานะ',
                    'จำนวนรายการ',
                    'ดำเนินการ'
                ],
                rows.map(row => `
                    <tr>
                        <td>${esc(row.request_no)}</td>
                        <td>${esc(row.requester_name)}</td>
                        <td>${esc(fmtDate(row.required_date))}</td>
                        <td>
                            ${badge(row.status)}
                            ${row.pickup_status ? badge(row.pickup_status) : ''}
                        </td>
                        <td>${esc(fmtNum(row.total_items))}</td>
                        <td>
                            ${
                                allowManage
                                    ? `<div class="actions">
                                        <button class="btn info"
                                            onclick="viewRequisition(${Number(row.id)})">
                                            รายละเอียด
                                        </button>
                                        ${
                                            row.status === 'PENDING'
                                                ? `
                                                    <button class="btn"
                                                        onclick="act('approve_requisition', ${Number(row.id)})">
                                                        อนุมัติ
                                                    </button>
                                                    <button class="btn danger"
                                                        onclick="act('reject_requisition', ${Number(row.id)})">
                                                        ปฏิเสธ
                                                    </button>
                                                `
                                                : ''
                                        }

                                        ${
                                            row.status === 'APPROVED' && row.pickup_status !== 'READY'
                                                ? `
                                                    <button class="btn"
                                                        onclick="act('ready_requisition', ${Number(row.id)})">
                                                        พร้อมรับ
                                                    </button>
                                                `
                                                : ''
                                        }

                                        ${
                                            row.status === 'APPROVED' &&
                                            row.pickup_status === 'READY'
                                                ? `
                                                    <button class="btn"
                                                        onclick="act('confirm_pickup', ${Number(row.id)})">
                                                        ยืนยันรับ
                                                    </button>
                                                `
                                                : ''
                                        }

                                        ${
                                            row.status !== 'PENDING' &&
                                            row.status !== 'APPROVED'
                                                ? '<span class="small muted">-</span>'
                                                : ''
                                        }
                                    </div>`
                                    : '<span class="small muted">-</span>'
                            }
                        </td>
                    </tr>
                `).join('')
            );
        }

        // Popup: รายละเอียดใบเบิก ประวัติ และการยืนยันทุกขั้นตอน
        window.closeRequisitionDetail = () => {
            document.getElementById('requisitionDetailModal')?.remove();
        };

        window.closeRequisitionActionModal = () => {
            document.getElementById('requisitionActionModal')?.remove();
        };

        function firstValue(obj, keys) {
            for (const key of keys) {
                if (obj && obj[key] !== undefined && obj[key] !== null && obj[key] !== '') return obj[key];
            }
            return null;
        }

        function requisitionDate(value) {
            return value ? fmtDateTime(value) : '-';
        }

        function buildRequisitionHistory(requisition) {
            const history = [];
            const push = (label, keys, status = '') => {
                const value = firstValue(requisition, keys);
                if (value) history.push({
                    label,
                    value: requisitionDate(value),
                    status
                });
            };

            push('สร้างใบเบิก', ['created_at', 'requested_at', 'request_date']);
            push('วันที่ต้องการใช้', ['required_date', 'needed_date']);
            push('อนุมัติ', ['approved_at', 'approve_at']);
            push('ปฏิเสธ', ['rejected_at', 'reject_at']);
            push('พร้อมรับ', ['ready_at', 'pickup_ready_at']);
            push('รับวัสดุแล้ว', ['picked_up_at', 'pickup_at', 'completed_at', 'issued_at']);

            const extra = requisition.history || requisition.status_history || requisition.activities || [];
            if (Array.isArray(extra)) {
                extra.forEach(item => {
                    const date = firstValue(item, ['created_at', 'date', 'timestamp', 'at']);
                    const label = firstValue(item, ['label', 'action_label', 'status_label', 'action', 'status']) || 'บันทึกสถานะ';
                    if (date) history.push({
                        label,
                        value: requisitionDate(date),
                        status: item.status || ''
                    });
                });
            }

            const unique = [];
            const seen = new Set();
            history.sort((a, b) => String(a.value).localeCompare(String(b.value)));
            history.forEach(item => {
                const key = `${item.label}|${item.value}`;
                if (!seen.has(key)) {
                    seen.add(key);
                    unique.push(item);
                }
            });
            return unique;
        }

        window.viewRequisition = async (id) => {
            try {
                const result = await api('admin/read_requisition', {
                    id
                });
                const requisition = result.data || {};
                const items = requisition.items || [];
                const rejectionReason = firstValue(requisition, [
                    'rejection_reason', 'reject_reason', 'rejection_comment', 'comment', 'admin_comment'
                ]);
                const history = buildRequisitionHistory(requisition);
                const modal = document.createElement('div');

                modal.id = 'requisitionDetailModal';
                modal.className = 'detail-modal-backdrop';
                modal.innerHTML = `
                    <section class="detail-modal requisition-detail-modal" role="dialog" aria-modal="true" aria-label="รายละเอียดใบเบิก">
                        <div class="detail-modal-head">
                            <div>
                                <div class="modal-eyebrow">รายละเอียดคำขอเบิก</div>
                                <h2>${esc(requisition.request_no || '-')}</h2>
                                <div class="modal-status-row">${badge(requisition.status)} ${requisition.pickup_status ? badge(requisition.pickup_status) : ''}</div>
                            </div>
                            <button class="modal-close-btn" type="button" onclick="closeRequisitionDetail()" aria-label="ปิด">×</button>
                        </div>

                        <div class="requester-hero">
                            <div class="requester-avatar">${esc(String(requisition.requester_name || '?').trim().charAt(0).toUpperCase())}</div>
                            <div>
                                <div class="requester-name">${esc(requisition.requester_name || '-')}</div>
                                <div class="requester-meta">รหัสพนักงาน ${esc(requisition.employee_code || '-')}</div>
                            </div>
                        </div>

                        <div class="detail-stat-grid">
                            <div class="detail-stat"><span>วันที่สร้าง</span><strong>${requisitionDate(firstValue(requisition, ['created_at', 'requested_at', 'request_date']))}</strong></div>
                            <div class="detail-stat"><span>วันที่ต้องการใช้</span><strong>${requisitionDate(firstValue(requisition, ['required_date', 'needed_date']))}</strong></div>
                            <div class="detail-stat"><span>จำนวนรายการ</span><strong>${esc(fmtNum(items.length))} รายการ</strong></div>
                            <div class="detail-stat"><span>จำนวนรวม</span><strong>${esc(fmtNum(requisition.total_quantity))} หน่วย</strong></div>
                        </div>

                        <div class="purpose-card">
                            <div class="purpose-icon">◎</div>
                            <div>
                                <div class="purpose-label">วัตถุประสงค์การเบิก</div>
                                <div class="purpose-text">${esc(firstValue(requisition, ['purpose', 'objective', 'request_purpose', 'requisition_purpose', 'reason']) || 'ไม่ได้ระบุวัตถุประสงค์')}</div>
                            </div>
                        </div>

                        ${rejectionReason ? `
                            <div class="rejection-note">
                                <div class="rejection-note-icon">!</div>
                                <div><strong>หมายเหตุจากแอดมิน</strong><p>${esc(rejectionReason)}</p></div>
                            </div>
                        ` : ''}

                        <div class="detail-section">
                            <div class="detail-section-head"><div><h3>รายการที่ขอเบิก</h3><p>ตรวจสอบวัสดุและจำนวนของผู้ขอเบิก</p></div></div>
                            ${table(
                                ['SKU', 'วัสดุ', 'จำนวนที่ขอ', 'อนุมัติ', 'หน่วย'],
                                items.map((item) => `
                                    <tr>
                                        <td>${esc(item.sku || '-')}</td>
                                        <td>
                                            <div class="product-cell">
                                                ${productThumb(item)}
                                                <strong>${esc(item.product_name || '-')}</strong>
                                            </div>
                                        </td>
                                        <td>${esc(fmtNum(item.requested_quantity))}</td>
                                        <td>${esc(fmtNum(item.approved_quantity))}</td>
                                        <td>${esc(item.unit || '-')}</td>
                                    </tr>
                                `).join('')
                            )}
                        </div>

                        <div class="detail-section">
                            <div class="detail-section-head"><div><h3>ประวัติวันที่</h3><p>ลำดับเหตุการณ์ที่มีข้อมูลจากระบบ</p></div></div>
                            ${history.length ? `
                                <div class="request-timeline">
                                    ${history.map((item, index) => `
                                        <div class="timeline-item">
                                            <div class="timeline-dot ${index === history.length - 1 ? 'current' : ''}"></div>
                                            <div><strong>${esc(item.label)}</strong><span>${esc(item.value)}</span></div>
                                        </div>
                                    `).join('')}
                                </div>
                            ` : `<div class="empty-history">ระบบยังไม่มีข้อมูลประวัติสถานะแยกต่างหาก</div>`}
                        </div>

                        <div class="detail-footer">
                            <button class="modal-btn secondary" type="button" onclick="closeRequisitionDetail()">ปิดหน้าต่าง</button>
                            ${requisition.status === 'PENDING' ? `
                                <button class="modal-btn danger" type="button" onclick="closeRequisitionDetail(); act('reject_requisition', ${Number(id)})">ปฏิเสธ</button>
                                <button class="modal-btn primary" type="button" onclick="closeRequisitionDetail(); act('approve_requisition', ${Number(id)})">อนุมัติ</button>
                            ` : ''}
                        </div>
                    </section>
                `;

                modal.addEventListener('click', (event) => {
                    if (event.target === modal) closeRequisitionDetail();
                });
                document.getElementById('requisitionDetailModal')?.remove();
                document.body.appendChild(modal);
            } catch (error) {
                showError(error);
            }
        };

        function openRequisitionActionModal({
            title,
            subtitle,
            body,
            confirmText,
            confirmClass = 'primary',
            onConfirm
        }) {
            document.getElementById('requisitionActionModal')?.remove();
            const modal = document.createElement('div');
            modal.id = 'requisitionActionModal';
            modal.className = 'action-modal-backdrop';
            modal.innerHTML = `
                <section class="action-modal" role="dialog" aria-modal="true">
                    <div class="action-modal-head">
                        <div><div class="modal-eyebrow">ยืนยันการดำเนินการ</div><h2>${esc(title)}</h2><p>${esc(subtitle || '')}</p></div>
                        <button class="modal-close-btn" type="button" onclick="closeRequisitionActionModal()">×</button>
                    </div>
                    <div class="action-modal-body">${body}</div>
                    <div class="action-modal-footer">
                        <button class="modal-btn secondary" type="button" onclick="closeRequisitionActionModal()">ยกเลิก</button>
                        <button id="actionModalConfirm" class="modal-btn ${confirmClass}" type="button">${esc(confirmText)}</button>
                    </div>
                </section>
            `;
            modal.addEventListener('click', event => {
                if (event.target === modal) closeRequisitionActionModal();
            });
            document.body.appendChild(modal);
            const confirmButton = document.getElementById('actionModalConfirm');
            confirmButton.onclick = async () => {
                confirmButton.disabled = true;
                confirmButton.innerHTML = '<span class="button-spinner"></span> กำลังดำเนินการ...';
                try {
                    await onConfirm(modal);
                } catch (error) {
                    confirmButton.disabled = false;
                    confirmButton.textContent = confirmText;
                    showError(error);
                }
            };
        }

        // Popup: แจ้งผลการทำรายการแบบเดียวกับทุกหน้าของระบบ
        window.showAdminMessageModal = ({
            title,
            message,
            type = 'success',
            buttonText = 'ตกลง'
        }) => {
            document.getElementById('adminMessageModal')?.remove();

            const modal = document.createElement('div');
            modal.id = 'adminMessageModal';
            modal.className = 'action-modal-backdrop';
            const icon = type === 'danger' ? '!' : type === 'info' ? 'i' : '✓';
            const buttonClass = type === 'danger' ? 'danger' : 'primary';

            modal.innerHTML = `
                <section class="action-modal compact-action-modal" role="dialog" aria-modal="true">
                    <div class="message-modal-icon ${esc(type)}">${icon}</div>
                    <div class="message-modal-content">
                        <div class="modal-eyebrow">ระบบคลังพัสดุ</div>
                        <h2>${esc(title)}</h2>
                        <p>${esc(message)}</p>
                    </div>
                    <div class="action-modal-footer message-modal-footer">
                        <button class="modal-btn ${buttonClass}" type="button"
                            onclick="document.getElementById('adminMessageModal')?.remove()">
                            ${esc(buttonText)}
                        </button>
                    </div>
                </section>
            `;

            modal.addEventListener('click', event => {
                if (event.target === modal) modal.remove();
            });

            document.body.appendChild(modal);
        };

        // หน้า: รายการเบิก
        async function requisitions() {
            heading('รายการเบิก', 'อนุมัติ ปฏิเสธ เตรียมรับ และยืนยันการรับวัสดุ');
            const result = await api('admin/read_requisitions');
            const rows = result.data || [];

            $('#pageBody').innerHTML = `
                <div class="toolbar">
                    <select id="reqFilter">
                        <option value="">ทุกสถานะ</option>
                        ${[
                            ['PENDING', 'รออนุมัติ'], ['APPROVED', 'อนุมัติแล้ว'], ['ISSUED', 'เบิกแล้ว'],
                            ['REJECTED', 'ปฏิเสธ'], ['CANCELLED', 'ยกเลิก']
                        ].map(([value, label]) => `<option value="${value}">${label}</option>`).join('')}
                    </select>
                </div>
                <div id="reqTable">${requestTable(rows, true)}</div>
            `;

            $('#reqFilter').onchange = () => {
                const filter = $('#reqFilter').value;
                $('#reqTable').innerHTML = requestTable(rows.filter(item => !filter || item.status === filter), true);
            };
        }

        window.act = async (action, id) => {
            try {
                if (action === 'approve_requisition') {
                    const detail = await api('admin/read_requisition', {
                        id
                    });
                    const requisition = detail.data || {};
                    const items = requisition.items || [];
                    const itemRows = items.map((item, index) => `
                        <div class="approve-item-row">
                            <div class="product-cell">${productThumb(item)}<div class="approve-item-info"><strong>${esc(item.product_name || '-')}</strong><span>${esc(item.sku || '-')} · ขอ ${esc(fmtNum(item.requested_quantity))} ${esc(item.unit || '')}</span></div></div>
                            <label class="approve-qty"><span>จำนวนอนุมัติ</span><input class="approve-qty-input" data-item-id="${Number(item.id)}" type="number" min="0" step="1" value="${Number(item.requested_quantity) || 0}"></label>
                        </div>
                    `).join('');

                    openRequisitionActionModal({
                        title: 'อนุมัติใบเบิก',
                        subtitle: `${requisition.request_no || '-'} · ${requisition.requester_name || '-'}`,
                        confirmText: 'ยืนยันอนุมัติ',
                        body: `<div class="action-info"><span>ตรวจสอบจำนวนก่อนยืนยัน</span><strong>${esc(fmtNum(items.length))} รายการ</strong></div><div class="approve-items">${itemRows || '<div class="empty-history">ไม่พบรายการวัสดุ</div>'}</div>`,
                        onConfirm: async (modal) => {
                            const approvedItems = [...modal.querySelectorAll('.approve-qty-input')].map(input => ({
                                item_id: Number(input.dataset.itemId),
                                approved_quantity: Number(input.value)
                            }));
                            if (approvedItems.some(item => !Number.isFinite(item.approved_quantity) || item.approved_quantity < 0)) {
                                throw new Error('กรุณาระบุจำนวนอนุมัติให้ถูกต้อง');
                            }
                            await api('admin/approve_requisition', {
                                id,
                                items: JSON.stringify(approvedItems)
                            });
                            closeRequisitionActionModal();
                            await loadPage('requisitions');
                        }
                    });
                    return;
                }

                if (action === 'reject_requisition') {
                    const detail = await api('admin/read_requisition', {
                        id
                    });
                    const requisition = detail.data || {};
                    openRequisitionActionModal({
                        title: 'ปฏิเสธใบเบิก',
                        subtitle: `${requisition.request_no || '-'} · ${requisition.requester_name || '-'}`,
                        confirmText: 'ยืนยันปฏิเสธ',
                        confirmClass: 'danger',
                        body: `<div class="reject-warning"><strong>โปรดระบุหมายเหตุ</strong><span>หมายเหตุนี้จะแสดงในรายละเอียดใบเบิก เพื่อให้ผู้ขอทราบเหตุผลที่รายการถูกปฏิเสธ</span></div><label class="modal-field"><span>หมายเหตุ / เหตุผลในการปฏิเสธ <b>*</b></span><textarea id="rejectReasonInput" rows="5" placeholder="เช่น สินค้าหมดชั่วคราว, จำนวนที่ขอเกินสิทธิ์ หรือกรุณาแก้ไขจำนวนใหม่"></textarea></label>`,
                        onConfirm: async () => {
                            const reason = document.getElementById('rejectReasonInput')?.value.trim() || '';
                            if (!reason) throw new Error('กรุณาระบุหมายเหตุในการปฏิเสธ');
                            await api('admin/reject_requisition', {
                                id,
                                comment: reason
                            });
                            closeRequisitionActionModal();
                            await loadPage('requisitions');
                        }
                    });
                    return;
                }

                if (action === 'ready_requisition') {
                    const detail = await api('admin/read_requisition', {
                        id
                    });
                    const requisition = detail.data || {};
                    openRequisitionActionModal({
                        title: 'เตรียมใบเบิกให้พร้อมรับ',
                        subtitle: `${requisition.request_no || '-'} · ${requisition.requester_name || '-'}`,
                        confirmText: 'ยืนยันพร้อมรับ',
                        body: `<div class="confirm-summary"><div class="confirm-icon success">✓</div><div><strong>พร้อมให้ผู้ขอมารับวัสดุ</strong><p>ระบบจะเปลี่ยนสถานะใบเบิกเป็น “พร้อมรับ”</p></div></div>`,
                        onConfirm: async () => {
                            await api('admin/ready_requisition', {
                                id
                            });
                            closeRequisitionActionModal();
                            await loadPage('requisitions');
                        }
                    });
                    return;
                }

                if (action === 'confirm_pickup') {
                    const detail = await api('admin/read_requisition', {
                        id
                    });
                    const requisition = detail.data || {};
                    const pickupCode = requisition.pickup?.pickup_code;
                    if (!pickupCode) throw new Error('ไม่พบรหัสรับวัสดุ กรุณาตรวจสอบว่าใบเบิกเตรียมพร้อมรับแล้ว');
                    openRequisitionActionModal({
                        title: 'ยืนยันการรับวัสดุ',
                        subtitle: `${requisition.request_no || '-'} · ${requisition.requester_name || '-'}`,
                        confirmText: 'ยืนยันรับวัสดุ',
                        body: `<div class="confirm-summary"><div class="confirm-icon success">✓</div><div><strong>ยืนยันว่าผู้ขอรับวัสดุแล้ว</strong><p>หลังยืนยัน ระบบจะบันทึกการจ่ายออกและเปลี่ยนสถานะเป็น “เบิกแล้ว”</p></div></div>`,
                        onConfirm: async () => {
                            await api('admin/confirm_pickup', {
                                pickup_code: pickupCode
                            });
                            closeRequisitionActionModal();
                            await loadPage('requisitions');
                        }
                    });
                }
            } catch (error) {
                showError(error);
            }
        };

        // Products

        // หน้า: สินค้าและวัสดุ
        async function products() {
            heading(
                'สินค้าและวัสดุ',
                'ดูยอดคงเหลือ ค้นหา และจัดการสินค้าในคลัง'
            );

            const [
                productResult,
                categoryResult
            ] = await Promise.all([
                api('admin/read_products'),
                api('admin/read_categories')
            ]);

            const rows = productResult.data || [];
            const categories = categoryResult.data || [];

            $('#pageBody').innerHTML = `
                <div class="toolbar">
                    <button class="primary" onclick="openProductModal()">
                        + เพิ่มสินค้า / วัสดุ
                    </button>

                    <input
                        id="productSearch"
                        placeholder="ค้นหาชื่อสินค้า, SKU หรือหมวดหมู่">

                    <button
                        class="btn secondary"
                        onclick="loadPage('products')">
                        รีเฟรช
                    </button>
                </div>

                <div id="productTable">
                    ${productTable(rows)}
                </div>
            `;

            $('#productSearch').oninput = () => {
                const keyword = $('#productSearch').value.toLowerCase();

                $('#productTable').innerHTML = productTable(
                    rows.filter(item => [
                        item.product_name,
                        item.sku,
                        item.category_name
                    ].join(' ').toLowerCase().includes(keyword))
                );
            };

            window.productCategories = categories;
        }

        // Popup: เพิ่มสินค้า/วัสดุ และแก้ไขข้อมูลสินค้า
        window.openProductModal = async (id = null) => {
            try {
                const categories = window.productCategories || [];
                let product = null;

                if (id) {
                    const result = await api('admin/read_product', {
                        id
                    });
                    product = result.data;
                }

                window.productModalEditingId = product?.id || null;
                window.productModalEditingStatus = product?.status || 'ACTIVE';

                const modal = document.createElement('div');
                modal.id = 'productModal';
                modal.className = 'modal-backdrop';

                modal.innerHTML = `
                    <section class="modal" role="dialog" aria-modal="true"
                        aria-label="${product ? 'แก้ไขสินค้า' : 'เพิ่มสินค้าและวัสดุ'}">

                        <div class="modal-head">
                            <div>
                                <h2 data-product-name>${product ? esc(product.product_name || 'สินค้า / วัสดุ') : 'เพิ่มสินค้า / วัสดุ'}</h2>
                                <div class="muted small">
                                    ${product
                                        ? 'แก้ไขข้อมูลของรายการที่เลือก'
                                        : 'กรอกข้อมูลเพื่อเพิ่มรายการใหม่เข้าคลัง'}
                                </div>
                            </div>
                            <button class="btn secondary" onclick="closeProductModal()">ปิด</button>
                        </div>

                        <form id="productModalForm">
                            <div class="product-image-preview">
                                <div id="productImagePreview">${productThumb(product || {}, 'lg')}</div>
                                <div class="muted small">
                                    รูปสินค้า<br>
                                    ระบบจะใช้ URL รูปภาพที่กรอก หากเว้นว่างจะดึงรูปจากโฟลเดอร์ uploads ตามชื่อวัสดุให้อัตโนมัติ
                                </div>
                            </div>

                            <div class="form-grid">
                                <label>
                                    รหัสพัสดุ (SKU)
                                    <input name="sku" required maxlength="100"
                                        value="${esc(product?.sku || '')}">
                                </label>

                                <label>
                                    ชื่อสินค้า / วัสดุ
                                    <input name="product_name" required maxlength="255"
                                        value="${esc(product?.product_name || '')}">
                                </label>

                                <label>
                                    หมวดหมู่
                                    <select name="category_id">
                                        <option value="">ไม่ระบุหมวดหมู่</option>
                                        ${categories.map(category => `
                                            <option value="${Number(category.id)}"
                                                ${String(product?.category_id || '') === String(category.id) ? 'selected' : ''}>
                                                ${esc(category.category_name)}
                                            </option>
                                        `).join('')}
                                    </select>
                                </label>

                                <label>
                                    หน่วยนับ
                                    <input name="unit" required maxlength="50"
                                        placeholder="เช่น ชิ้น, กล่อง"
                                        value="${esc(product?.unit || '')}">
                                </label>

                                ${
                                    product
                                        ? ''
                                        : `
                                            <label>
                                                จำนวนเริ่มต้น
                                                <input name="initial_stock" type="number"
                                                    min="0" step="1" value="0">
                                            </label>
                                        `
                                }

                                <label>
                                    จำนวนขั้นต่ำ
                                    <input name="minimum_stock" type="number"
                                        min="0" step="1"
                                        value="${esc(product?.minimum_stock ?? 0)}">
                                </label>

                                <label>
                                    จำนวนสูงสุด
                                    <span class="small muted">0 = ไม่กำหนด</span>
                                    <input name="maximum_stock" type="number"
                                        min="0" step="1"
                                        value="${esc(product?.maximum_stock ?? 0)}">
                                </label>

                                <label>
                                    URL รูปภาพ
                                    <input name="image_url" type="url"
                                        value="${esc(product?.image_url || '')}">
                                </label>
                            </div>

                            <label style="margin-top:14px">
                                รายละเอียด
                                <textarea name="description" rows="3">${esc(product?.description || '')}</textarea>
                            </label>

                            <div class="actions" style="justify-content:flex-end;margin-top:18px">
                                <button type="button" class="btn secondary"
                                    onclick="closeProductModal()">ยกเลิก</button>
                                <button class="primary">
                                    ${product ? 'บันทึกการแก้ไข' : 'เพิ่มสินค้า / วัสดุ'}
                                </button>
                            </div>
                        </form>

                        ${
                            product
                                ? `
                                    <div class="modal-section">
                                        <h3>รับสินค้า / วัสดุเข้าเพิ่ม</h3>
                                        <div class="muted small" style="margin-bottom:12px">
                                            คงเหลือปัจจุบัน ${fmtNum(product.available_quantity)} ${esc(product.unit || '')}
                                        </div>
                                        <div class="actions">
                                            <input id="modalReceiveQty" type="number"
                                                min="1" step="1" placeholder="จำนวนที่รับเข้า">
                                            <button class="btn" onclick="receiveStockFromModal(${Number(product.id)})">
                                                รับเข้า
                                            </button>
                                        </div>
                                    </div>

                                    <div class="modal-section">
                                        <h3>สถานะรายการ</h3>
                                        <button class="btn danger"
                                            onclick="deactivateProductFromModal(${Number(product.id)})">
                                            ปิดใช้งานวัสดุ
                                        </button>
                                    </div>
                                `
                                : ''
                        }
                    </section>
                `;

                modal.addEventListener('click', event => {
                    if (event.target === modal) closeProductModal();
                });

                document.getElementById('productModal')?.remove();
                document.body.appendChild(modal);

                const productForm = document.getElementById('productModalForm');

                productForm.addEventListener(
                    'submit',
                    product ? updateProductFromModal : createProduct
                );

                // อัปเดตรูปตัวอย่างทันทีเมื่อแก้ชื่อหรือ URL รูปภาพ
                const refreshPreview = () => {
                    document.getElementById('productImagePreview').innerHTML =
                        productThumb({
                            product_name: productForm.product_name.value,
                            image_url: productForm.image_url.value
                        }, 'lg');
                };
                productForm.product_name.addEventListener('input', refreshPreview);
                productForm.image_url.addEventListener('input', refreshPreview);
                refreshPreview();
            } catch (error) {
                showError(error);
            }
        };

        window.closeProductModal = () => {
            document.getElementById('productModal')?.remove();
        };

        window.receiveStockFromModal = async (id) => {
            const input = document.getElementById('modalReceiveQty');
            const quantity = input?.value || '';

            if (!/^\d+$/.test(quantity) || Number(quantity) < 1) {
                showAdminMessageModal({
                    title: 'จำนวนไม่ถูกต้อง',
                    message: 'กรุณาระบุจำนวนเต็มตั้งแต่ 1 ขึ้นไป',
                    type: 'danger'
                });
                return;
            }

            const productName = document.querySelector('#productModal [data-product-name]')?.textContent || 'รายการนี้';

            openRequisitionActionModal({
                title: 'ยืนยันรับสินค้า / วัสดุเข้า',
                subtitle: productName,
                confirmText: 'ยืนยันรับเข้า',
                body: `
                    <div class="inventory-confirm-card">
                        <div class="inventory-confirm-icon">↓</div>
                        <div>
                            <span>จำนวนที่จะรับเข้า</span>
                            <strong>${esc(fmtNum(quantity))} หน่วย</strong>
                            <p>ระบบจะเพิ่มจำนวนเข้าสต็อกและบันทึกประวัติการรับเข้า</p>
                        </div>
                    </div>
                `,
                onConfirm: async () => {
                    await api('admin/inventory_in', {
                        product_id: id,
                        quantity: Number(quantity)
                    });

                    closeRequisitionActionModal();
                    closeProductModal();
                    await loadPage('products');

                    showAdminMessageModal({
                        title: 'รับสินค้าเข้าเรียบร้อย',
                        message: `เพิ่มเข้าสต็อกจำนวน ${fmtNum(quantity)} หน่วยสำเร็จ`
                    });
                }
            });
        };

        window.deactivateProductFromModal = async (id) => {
            const productName = document.querySelector('#productModal [data-product-name]')?.textContent || 'วัสดุรายการนี้';

            openRequisitionActionModal({
                title: 'ปิดใช้งานวัสดุ',
                subtitle: productName,
                confirmText: 'ยืนยันปิดใช้งาน',
                confirmClass: 'danger',
                body: `
                    <div class="inventory-confirm-card danger-card">
                        <div class="inventory-confirm-icon danger">!</div>
                        <div>
                            <strong>ต้องการปิดใช้งานรายการนี้หรือไม่?</strong>
                            <p>รายการเดิมจะยังคงอยู่ในประวัติคลัง แต่จะไม่สามารถใช้งานเป็นรายการปกติได้</p>
                        </div>
                    </div>
                `,
                onConfirm: async () => {
                    await api('admin/delete_product', {
                        id
                    });

                    closeRequisitionActionModal();
                    closeProductModal();
                    await loadPage('products');

                    showAdminMessageModal({
                        title: 'ปิดใช้งานวัสดุแล้ว',
                        message: 'รายการยังคงอยู่ในประวัติคลังและสามารถตรวจสอบย้อนหลังได้'
                    });
                }
            });
        };

        async function updateProductFromModal(event) {
            event.preventDefault();

            const form = event.currentTarget;
            const data = Object.fromEntries(new FormData(form).entries());
            const id = window.productModalEditingId;

            try {
                await api('admin/update_product', {
                    id,
                    sku: data.sku,
                    product_name: data.product_name,
                    description: data.description || '',
                    category_id: data.category_id || '',
                    unit: data.unit,
                    image_url: data.image_url || '',
                    minimum_stock: data.minimum_stock || 0,
                    maximum_stock: data.maximum_stock || 0,
                    status: window.productModalEditingStatus || 'ACTIVE'
                });

                closeProductModal();
                await loadPage('products');
                showAdminMessageModal({
                    title: 'บันทึกข้อมูลสำเร็จ',
                    message: 'แก้ไขข้อมูลสินค้า / วัสดุเรียบร้อยแล้ว'
                });
            } catch (error) {
                showError(error);
            }
        }

        async function createProduct(event) {
            event.preventDefault();

            const form = event.currentTarget;
            const data = Object.fromEntries(new FormData(form).entries());
            const startingStock = Number(data.initial_stock || 0);
            delete data.initial_stock;

            try {
                const created = await api('admin/create_product', data);

                if (startingStock > 0) {
                    await api('admin/inventory_in', {
                        product_id: created.id ?? created.data?.id,
                        quantity: startingStock
                    });
                }

                closeProductModal();
                await loadPage('products');
                showAdminMessageModal({
                    title: 'เพิ่มสินค้า / วัสดุสำเร็จ',
                    message: 'รายการใหม่ถูกเพิ่มเข้าคลังเรียบร้อยแล้ว'
                });
            } catch (error) {
                showError(error);
            }
        }

        function productTable(rows) {
            return table(
                [
                    'SKU',
                    'ชื่อสินค้า',
                    'หมวดหมู่',
                    'คงเหลือจริง',
                    'จองแล้ว',
                    'พร้อมให้เบิก',
                    'หน่วย',
                    'ขั้นต่ำ',
                    'สถานะ',
                    'จัดการ'
                ],
                rows
                .map(
                    (item) => `
                            <tr>

                                <td>
                                    ${esc(item.sku)}
                                </td>

                                <td>
                                    <div class="product-cell">
                                        ${productThumb(item)}
                                        <span>${esc(item.product_name)}</span>
                                    </div>
                                </td>

                                <td>
                                    ${esc(item.category_name || 'ไม่ระบุหมวดหมู่')}
                                </td>

                                <td>
                                    ${esc(fmtNum(item.stock_quantity))}
                                </td>

                                <td>
                                    ${esc(fmtNum(item.reserved_quantity))}
                                </td>

                                <td>
                                    ${esc(fmtNum(item.available_quantity))}
                                </td>

                                <td>
                                    ${esc(item.unit)}
                                </td>

                                <td>
                                    ${esc(fmtNum(item.minimum_stock))}
                                </td>

                                <td>
                                    ${badge(stockStatus(item))}
                                </td>

                                <td>
                                    <button
                                        class="btn secondary"
                                        onclick="openProductModal(${Number(item.id)})"
                                    >
                                        จัดการวัสดุ
                                    </button>
                                </td>

                            </tr>
                        `
                )
                .join('')
            );
        }

        // หน้า: ประวัติคลัง
        async function transactions() {
            heading(
                'ประวัติคลัง',
                'รายการรับเข้า เบิกจ่าย และปรับยอด'
            );

            const result =
                await api(
                    'admin/read_inventory_transactions'
                );

            const rows =
                result.data || [];

            $('#pageBody').innerHTML =
                table(
                    [
                        'วันเวลา',
                        'สินค้า',
                        'ประเภท',
                        'จำนวน',
                        'ก่อน',
                        'หลัง',
                        'ผู้ดำเนินการ',
                        'อ้างอิง'
                    ],
                    rows
                    .map(
                        (item) => `
                                <tr>
                                    <td>
                                        ${esc(fmtDateTime(item.created_at))}
                                    </td>

                                    <td>
                                        ${esc(item.product_name)}
                                    </td>

                                    <td>
                                        ${badge(item.transaction_type)}
                                    </td>

                                    <td>
                                        ${esc(fmtNum(item.quantity))}
                                    </td>

                                    <td>
                                        ${esc(fmtNum(item.before_quantity))}
                                    </td>

                                    <td>
                                        ${esc(fmtNum(item.after_quantity))}
                                    </td>

                                    <td>
                                        ${esc(item.admin_name || '-')}
                                    </td>

                                    <td>
                                        ${esc(refLabel(item.reference_type))}
                                    </td>
                                </tr>
                            `
                    )
                    .join('')
                );
        }

        // หน้า: การแจ้งเตือน
        async function notifications() {
            heading(
                'การแจ้งเตือน',
                'ติดตามคำขอและเหตุการณ์สำคัญของระบบคลัง'
            );

            const result = await api('admin/read_notifications');
            const rows = result.data || [];

            const unread = rows.filter(item => !item.is_read).length;

            $('#pageBody').innerHTML = `
                <div class="notification-summary">
                    <div>
                        <span class="notification-summary-label">การแจ้งเตือนทั้งหมด</span>
                        <strong>${esc(fmtNum(rows.length))}</strong>
                    </div>
                    <div class="notification-unread-count">
                        <span class="notification-dot"></span>
                        <span>ยังไม่อ่าน ${esc(fmtNum(unread))} รายการ</span>
                    </div>
                </div>

                <div class="notification-list">
                    ${
                        rows.length
                            ? rows.map(item => `
                                <article
                                    class="notification-card ${item.is_read ? 'read' : 'unread'}"
                                    role="button"
                                    tabindex="0"
                                    onclick="openNotification(${Number(item.id)})"
                                    onkeydown="if(event.key==='Enter' || event.key===' ') { event.preventDefault(); openNotification(${Number(item.id)}); }"
                                >
                                    <div class="notification-card-icon ${item.is_read ? 'read' : 'unread'}">
                                        ${item.is_read ? '✓' : '!'}
                                    </div>

                                    <div class="notification-card-main">
                                        <div class="notification-card-top">
                                            <div>
                                                <strong>${esc(item.title || 'การแจ้งเตือน')}</strong>
                                                ${!item.is_read ? '<span class="notification-new">ใหม่</span>' : ''}
                                            </div>
                                            <time>${esc(fmtDateTime(item.created_at))}</time>
                                        </div>

                                        <p>${esc(item.message || '-')}</p>

                                        <div class="notification-card-bottom">
                                            <span class="notification-status ${item.is_read ? 'read' : 'unread'}">
                                                ${item.is_read ? 'อ่านแล้ว' : 'ยังไม่อ่าน'}
                                            </span>
                                            ${
                                                getNotificationRequisitionId(item)
                                                    ? '<span class="notification-link">เปิดรายละเอียดใบเบิก →</span>'
                                                    : '<span class="notification-link">เปิดการแจ้งเตือน →</span>'
                                            }
                                        </div>
                                    </div>
                                </article>
                            `).join('')
                            : `
                                <div class="notification-empty">
                                    <div class="notification-empty-icon">✓</div>
                                    <strong>ไม่มีการแจ้งเตือน</strong>
                                    <p>ขณะนี้ยังไม่มีรายการแจ้งเตือนใหม่</p>
                                </div>
                            `
                    }
                </div>
            `;
        }

        function getNotificationRequisitionId(item) {
            const nested = item.data && typeof item.data === 'object' ?
                item.data :
                {};

            const value =
                item.requisition_id ??
                item.request_id ??
                item.reference_id ??
                item.related_id ??
                item.entity_id ??
                nested.requisition_id ??
                nested.request_id ??
                nested.reference_id ??
                null;

            const n = Number(value);
            return Number.isFinite(n) && n > 0 ? n : null;
        }

        async function resolveNotificationRequisitionId(item) {
            const directId = getNotificationRequisitionId(item);
            if (directId) return directId;

            const requestNo =
                item.request_no ||
                item.requisition_no ||
                item.data?.request_no ||
                item.data?.requisition_no;

            if (!requestNo) return null;

            const result = await api('admin/read_requisitions');
            const match = (result.data || []).find(row =>
                String(row.request_no || '') === String(requestNo)
            );

            return match ? Number(match.id) : null;
        }

        window.openNotification = async (id) => {
            try {
                const result = await api('admin/read_notifications');
                const item = (result.data || []).find(row => Number(row.id) === Number(id));

                if (!item) {
                    await loadPage('notifications');
                    return;
                }

                if (!item.is_read) {
                    await api('admin/mark_notification_read', {
                        id
                    });
                }

                const requisitionId = await resolveNotificationRequisitionId(item);

                if (requisitionId) {
                    await viewRequisition(requisitionId);
                } else {
                    showAdminMessageModal({
                        title: item.title || 'การแจ้งเตือน',
                        message: item.message || 'เปิดการแจ้งเตือนแล้ว',
                        type: 'info'
                    });
                    await loadPage('notifications');
                }
            } catch (error) {
                showError(error);
            }
        };

        window.markRead = async (id) => {
            try {
                await api('admin/mark_notification_read', {
                    id
                });
                await loadPage('notifications');
            } catch (error) {
                showError(error);
            }
        };

        // หน้า: เปลี่ยนรหัสผ่าน
        function security() {
            heading(
                'เปลี่ยนรหัสผ่าน',
                'ยืนยันรหัสผ่านปัจจุบันก่อนตั้งรหัสผ่านใหม่'
            );

            $('#pageBody').innerHTML = `
                <form
                    id="passwordForm"
                    class="panel"
                    style="max-width:520px"
                >

                    <div
                        class="notice"
                        id="passwordMessage"
                    ></div>

                    <label for="currentPassword">
                        รหัสผ่านปัจจุบัน
                    </label>

                    <input
                        id="currentPassword"
                        type="password"
                        autocomplete="current-password"
                        required
                        style="width:100%"
                    >

                    <label for="newPassword">
                        รหัสผ่านใหม่
                        (อย่างน้อย 12 ตัวอักษร)
                    </label>

                    <input
                        id="newPassword"
                        type="password"
                        autocomplete="new-password"
                        minlength="12"
                        required
                        style="width:100%"
                    >

                    <label for="confirmPassword">
                        ยืนยันรหัสผ่านใหม่
                    </label>

                    <input
                        id="confirmPassword"
                        type="password"
                        autocomplete="new-password"
                        minlength="12"
                        required
                        style="width:100%"
                    >

                    <button
                        class="primary"
                        style="margin-top:18px"
                    >
                        บันทึกรหัสผ่านใหม่
                    </button>

                </form>
            `;

            $('#passwordForm')
                .addEventListener(
                    'submit',
                    async (event) => {
                        event.preventDefault();

                        const message =
                            $('#passwordMessage');

                        message.textContent = '';

                        try {
                            const result =
                                await api(
                                    'admin/change_password', {
                                        current_password: $('#currentPassword')
                                            .value,

                                        new_password: $('#newPassword')
                                            .value,

                                        confirm_password: $('#confirmPassword')
                                            .value
                                    }
                                );

                            message.style.color =
                                '#17723b';

                            message.textContent =
                                result.message;

                            sessionStorage.clear();
                            token = '';

                            setTimeout(
                                () =>
                                setSignedIn(false),
                                1200
                            );

                        } catch (error) {
                            message.textContent =
                                error.message;
                        }
                    }
                );
        }

        // เริ่มต้นระบบและตรวจสอบ session
        (async () => {
            if (!token) {
                setSignedIn(false);
                return;
            }

            try {
                const result =
                    await api(
                        'admin/read_admin'
                    );

                currentAdmin =
                    result.admin;

                $('#adminName').textContent =
                    currentAdmin.name ||
                    currentAdmin.username;

                setSignedIn(true);

                loadPage(INITIAL_PAGE);

            } catch (_) {
                sessionStorage.clear();
                token = '';

                setSignedIn(false);
            }
        })();
    </script>

</body>

</html>
