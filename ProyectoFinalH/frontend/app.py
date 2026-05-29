import os
import time
from datetime import datetime

from flask import Flask, Response, jsonify, render_template, request
from prometheus_client import Counter, Gauge, Histogram, generate_latest

app = Flask(__name__)

# ── Métricas de negocio ──────────────────────────────────────────────────────
PURCHASES_TOTAL = Counter(
    "store_purchases_total",
    "Total de compras realizadas en la tienda",
)
REVENUE_TOTAL = Counter(
    "store_revenue_total_usd",
    "Ingresos totales acumulados en USD",
)
KEYS_DELIVERED = Counter(
    "store_keys_delivered_total",
    "Total de claves digitales entregadas a los clientes",
)
CART_ABANDONED = Counter(
    "store_cart_abandoned_total",
    "Total de carritos abandonados sin completar la compra",
)
DISCOUNTS_APPLIED = Counter(
    "store_discounts_applied_total",
    "Total de descuentos aplicados en compras",
)
WISHLIST_ADDITIONS = Counter(
    "store_wishlist_additions_total",
    "Total de juegos añadidos a favoritos",
)
SEARCHES_TOTAL = Counter(
    "store_searches_total",
    "Total de búsquedas realizadas en la tienda",
)

# ── Métricas por dimensión ───────────────────────────────────────────────────
GAME_SALES = Counter(
    "store_game_sales_total",
    "Unidades vendidas por juego",
    ["game_name"],
)
SALES_BY_CATEGORY = Counter(
    "store_sales_by_category_total",
    "Ventas agrupadas por categoría de juego",
    ["category"],
)
SALES_BY_PLATFORM = Counter(
    "store_sales_by_platform_total",
    "Ventas agrupadas por plataforma",
    ["platform"],
)

# ── Métricas en tiempo real ──────────────────────────────────────────────────
ACTIVE_USERS = Gauge(
    "store_active_users",
    "Usuarios navegando la tienda en este momento",
)
CART_ITEMS_CURRENT = Gauge(
    "store_cart_items_current",
    "Productos en carritos activos en este momento",
)

# ── Métricas web ─────────────────────────────────────────────────────────────
PAGE_VISITS = Counter(
    "store_page_visits_total",
    "Total de visitas a las páginas de la tienda",
    ["path", "method", "status"],
)
REQUEST_LATENCY = Histogram(
    "store_request_latency_seconds",
    "Tiempo de respuesta de la tienda",
    ["path"],
)


@app.before_request
def before_request():
    request.start_time = time.time()


@app.after_request
def after_request(response):
    path = request.path
    elapsed = time.time() - request.start_time
    REQUEST_LATENCY.labels(path=path).observe(elapsed)
    if path != "/metrics":
        PAGE_VISITS.labels(
            path=path,
            method=request.method,
            status=response.status_code,
        ).inc()
    return response


@app.route("/")
def home():
    return render_template("index.html", year=datetime.now().year)


@app.route("/api/store/event", methods=["POST"])
def store_event():
    data = request.get_json(silent=True) or {}
    event = data.get("event", "")

    # ── Usuario entra o sale de la tienda ────────────────────────────────────
    if event == "user_enter":
        ACTIVE_USERS.inc()

    elif event == "user_leave":
        ACTIVE_USERS.dec()

    # ── Carrito ───────────────────────────────────────────────────────────────
    elif event == "cart_add":
        quantity = max(1, int(data.get("quantity", 1)))
        CART_ITEMS_CURRENT.inc(quantity)

    elif event == "cart_remove":
        quantity = max(1, int(data.get("quantity", 1)))
        CART_ITEMS_CURRENT.dec(quantity)

    elif event == "cart_abandon":
        items = max(0, int(data.get("items", 0)))
        CART_ABANDONED.inc()
        if items > 0:
            CART_ITEMS_CURRENT.dec(items)

    # ── Compra completada ─────────────────────────────────────────────────────
    elif event == "purchase":
        price     = max(0.0, float(data.get("price", 0.0)))
        game_name = data.get("game_name", "unknown")
        category  = data.get("category", "unknown")
        platform  = data.get("platform", "unknown")
        discounted = data.get("discounted", False)

        PURCHASES_TOTAL.inc()
        KEYS_DELIVERED.inc()
        if price > 0:
            REVENUE_TOTAL.inc(price)
        GAME_SALES.labels(game_name=game_name).inc()
        SALES_BY_CATEGORY.labels(category=category).inc()
        SALES_BY_PLATFORM.labels(platform=platform).inc()
        if discounted:
            DISCOUNTS_APPLIED.inc()

        # Descontar del carrito activo
        CART_ITEMS_CURRENT.dec()

    # ── Favoritos ─────────────────────────────────────────────────────────────
    elif event == "wishlist_add":
        WISHLIST_ADDITIONS.inc()

    # ── Búsqueda ──────────────────────────────────────────────────────────────
    elif event == "search":
        SEARCHES_TOTAL.inc()

    return jsonify({"ok": True})


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype="text/plain; version=0.0.4")


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)