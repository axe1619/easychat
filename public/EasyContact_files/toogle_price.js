
const global_toogle_price = {
    price: {
        select: "MONTH",
        option: {
            YEAR: "YEAR",
            MONTH: "MONTH",
        }
    },
    currency: {
        select: {
            key: "BOB",
            value: "Bs"
        },
        option: {
            BOB: "Bs",
            USD: "$us",
        }
    },
    annual_discount: 0.8,
    base_monthly: {
        BOB: {
            price_startup: 396,
            price_business: 492,
            price_enterprice: 896
        },
        USD: {
            price_startup: 57,
            price_business: 71,
            price_enterprice: 129
        }
    },
    plan_includes: {
        price_startup: { conversations: 2000, agents: 1, users: 3, channels: 1 },
        price_business: { conversations: 4000, agents: 1, users: 5, channels: 2 },
        price_enterprice: { conversations: 5000, agents: 3, users: 10, channels: 2 }
    },
    addons_usd: {
        agent: 19,
        user: 15,
        channel: 10,
        conv_block: 9,
        conv_block_size: 2000
    },
    selected_plan: "price_business",
    plan_links: {
        price_startup: "https://wa.me/59161332756?text=Me%20interesa%20el%20plan%20startups%20de%20easycontact,%20quisiera%20comprarlo",
        price_business: "https://wa.me/59161332756?text=Me%20interesa%20el%20plan%20business%20de%20easycontact,%20quisiera%20comprarlo",
        price_enterprice: "https://wa.me/59161332756?text=Me%20interesa%20el%20plan%20enterprise%20de%20easycontact,%20quisiera%20comprarlo"
    }
}

document.addEventListener("DOMContentLoaded", () => {
    init()
    document.querySelector("#toogle_price").addEventListener('change', (e) => on_change_toogle_price(e))
    document.querySelectorAll(".currency-option").forEach((option) => {
        option.addEventListener("click", () => {
            select_option(option.dataset.flag, option.dataset.key, option.dataset.value)
        })
    })
    document.querySelectorAll("[data-card-stepper]").forEach((button) => {
        button.addEventListener("click", () => {
            const card = button.closest("[data-plan-card]")
            if (!card) return
            const field = button.dataset.field
            const delta = to_delta(button.dataset.delta)
            const current = to_int(card.dataset[field])
            const next = Math.max(0, current + (delta || 0))
            card.dataset[field] = next
            update_card(card)
            update_summary(card.dataset.planCard)
        })
    })
    document.querySelectorAll("[data-plan-key]").forEach((card) => {
        card.addEventListener("click", (event) => {
            if (event.target.closest("[data-card-stepper]") || event.target.closest("a") || event.target.closest("button")) {
                return
            }
            select_plan(card.dataset.planKey)
        })
    })
    setup_cart_visibility()
    document.addEventListener('click', (e) => on_click_page(e));
});

// events handler

function on_change_toogle_price(e) {
    if (e.currentTarget.checked) {
        global_toogle_price.price.select = global_toogle_price.price.option.YEAR
        toogle_price(global_toogle_price.price.select)
        return
    }
    global_toogle_price.price.select = global_toogle_price.price.option.MONTH
    toogle_price(global_toogle_price.price.select)
}

function on_click_page(e) {
    const dropdown = document.getElementById('dropdown_price');
    const button = document.getElementById('dropdown_btn');
    if (!button.contains(e.target) && !dropdown.contains(e.target)) {
        dropdown.classList.add('hidden');
    }
}

// functions

function init() {
    toogle_price(global_toogle_price.price.select)
    init_plan_cards()
}

function toogle_price(price) {
    const plans = get_plans_for_selection()
    Object.entries(plans).forEach(([plan, value]) => {
        if (price == global_toogle_price.price.option.YEAR) {
            document.querySelector(`#${plan}_month_anual`).classList.add("line-through")
            document.querySelector(`#${plan}_month_anual`).textContent = `${value.month * 12} ${global_toogle_price.currency.select.value}/año`
            document.querySelector(`#${plan}`).textContent = `${value.year} ${global_toogle_price.currency.select.value}/año`
            document.querySelector("#plan_selected").textContent = "Plan anual"
            return
        }
        document.querySelector(`#${plan}_month_anual`).classList.remove("line-through")
        document.querySelector(`#${plan}_month_anual`).textContent = `${value.month * 12} ${global_toogle_price.currency.select.value}/año`
        document.querySelector(`#${plan}`).textContent = `${value.month} ${global_toogle_price.currency.select.value}/mes`
        document.querySelector("#plan_selected").textContent = "Plan mensual"
    });
    update_all_cards()
}

function get_plans_for_selection() {
    const basePlans = global_toogle_price.base_monthly[global_toogle_price.currency.select.key]
    return Object.entries(basePlans).reduce((acc, [plan, month]) => {
        const yearPrice = Math.round(month * 12 * global_toogle_price.annual_discount)
        acc[plan] = { month, year: yearPrice }
        return acc
    }, {})
}

function init_plan_cards() {
    document.querySelectorAll("[data-plan-card]").forEach((card) => {
        card.dataset.agents = card.dataset.agents || "0"
        card.dataset.users = card.dataset.users || "0"
        card.dataset.conversations = card.dataset.conversations || "0"
        card.dataset.channels = card.dataset.channels || "0"
        update_card(card)
    })
    update_summary(global_toogle_price.selected_plan)
}

function update_all_cards() {
    document.querySelectorAll("[data-plan-card]").forEach((card) => update_card(card))
    update_summary(global_toogle_price.selected_plan)
}

function update_card(card) {
    const planKey = card.dataset.planCard
    const basePlans = global_toogle_price.base_monthly[global_toogle_price.currency.select.key]
    const baseMonthly = basePlans[planKey]
    const currencyValue = global_toogle_price.currency.select.value

    const agents = to_int(card.dataset.agents)
    const users = to_int(card.dataset.users)
    const extraConversations = to_int(card.dataset.conversations)
    const channels = to_int(card.dataset.channels)
    const extraBlocks = Math.ceil(extraConversations / global_toogle_price.addons_usd.conv_block_size)

    const addons = get_addon_prices()
    const extrasMonthly = (agents * addons.agent) + (users * addons.user) + (channels * addons.channel) + (extraBlocks * addons.conv_block)
    const totalMonthly = baseMonthly + extrasMonthly

    const isYear = global_toogle_price.price.select === global_toogle_price.price.option.YEAR
    const totalValue = isYear ? Math.round(totalMonthly * 12 * global_toogle_price.annual_discount) : Math.round(totalMonthly)
    const totalLabel = isYear ? "año" : "mes"

    card.querySelectorAll("[data-count]").forEach((countEl) => {
        const field = countEl.dataset.count
        const value = field === "conversations" ? format_number(extraConversations) : card.dataset[field]
        countEl.textContent = value || "0"
    })

    const totalEl = card.querySelector("[data-total-price]")
    if (totalEl) {
        totalEl.textContent = `${format_number(totalValue)} ${currencyValue}/${totalLabel}`
    }

    const annualNote = card.querySelector("[data-annual-note]")
    if (annualNote) {
        if (isYear) {
            const annualValue = format_number(Math.round(totalMonthly * 12 * global_toogle_price.annual_discount))
            annualNote.textContent = `Un solo pago desde ${annualValue} ${currencyValue}`
        } else {
            annualNote.textContent = ""
        }
    }

    const includes = global_toogle_price.plan_includes[planKey]
    card.querySelectorAll("[data-include]").forEach((includeEl) => {
        const field = includeEl.dataset.include
        if (!includes || !Object.prototype.hasOwnProperty.call(includes, field)) return
        const includeValue = field === "conversations"
            ? `${format_number(includes[field])} conversaciones incluidas`
            : `Incluye ${includes[field]}`
        includeEl.textContent = includeValue
    })
}

function update_summary(planKey) {
    const card = document.querySelector(`[data-plan-card="${planKey}"]`)
    if (!card) return
    global_toogle_price.selected_plan = planKey
    const planLabel = planKey === "price_startup" ? "Startups" : planKey === "price_business" ? "Business" : "Enterprise"
    const basePlans = global_toogle_price.base_monthly[global_toogle_price.currency.select.key]
    const baseMonthly = basePlans[planKey]
    const currencyValue = global_toogle_price.currency.select.value

    const agents = to_int(card.dataset.agents)
    const users = to_int(card.dataset.users)
    const channels = to_int(card.dataset.channels)
    const extraConversations = to_int(card.dataset.conversations)
    const extraBlocks = Math.ceil(extraConversations / global_toogle_price.addons_usd.conv_block_size)

    const addons = get_addon_prices()
    const extrasMonthly = (agents * addons.agent) + (users * addons.user) + (channels * addons.channel) + (extraBlocks * addons.conv_block)
    const totalMonthly = baseMonthly + extrasMonthly

    const isYear = global_toogle_price.price.select === global_toogle_price.price.option.YEAR
    const totalValue = isYear ? Math.round(totalMonthly * 12 * global_toogle_price.annual_discount) : Math.round(totalMonthly)
    const totalLabel = isYear ? "año" : "mes"

    document.querySelector("#summary_plan").textContent = planLabel
    document.querySelector("#summary_total").textContent = `${format_number(totalValue)} ${currencyValue}/${totalLabel}`
    document.querySelector("#summary_base").textContent = `${format_number(baseMonthly)} ${currencyValue}/mes`
    document.querySelector("#summary_extras").textContent = `${format_number(extrasMonthly)} ${currencyValue}/mes`
    document.querySelector("#summary_conversations").textContent = `${format_number(extraConversations)}`
    document.querySelector("#summary_counts").textContent = `${agents}/${users}/${channels}`

    update_selected_card(planKey)
    update_cart(planLabel, totalValue, totalLabel, baseMonthly, extrasMonthly, currencyValue, isYear, agents, users, channels, extraConversations)

    const annualSummary = document.querySelector("#summary_annual")
    if (annualSummary) {
        if (isYear) {
            annualSummary.textContent = `Un solo pago desde ${format_number(Math.round(totalMonthly * 12 * global_toogle_price.annual_discount))} ${currencyValue}`
        } else {
            annualSummary.textContent = ""
        }
    }
}

function select_plan(planKey) {
    update_summary(planKey)
}

function update_selected_card(planKey) {
    document.querySelectorAll("[data-plan-key]").forEach((card) => {
        card.classList.toggle("selected-card", card.dataset.planKey === planKey)
    })
}

function update_cart(planLabel, totalValue, totalLabel, baseMonthly, extrasMonthly, currencyValue, isYear, agents, users, channels, extraConversations) {
    const cartPlan = document.querySelector("#cart_plan")
    const cartTotal = document.querySelector("#cart_total")
    const cartBase = document.querySelector("#cart_base")
    const cartExtras = document.querySelector("#cart_extras")
    const cartAnnual = document.querySelector("#cart_annual")
    const cartBuy = document.querySelector("#cart_buy")

    if (cartPlan) cartPlan.textContent = planLabel
    if (cartTotal) cartTotal.textContent = `${format_number(totalValue)} ${currencyValue}/${totalLabel}`
    if (cartBase) cartBase.textContent = `${format_number(baseMonthly)} ${currencyValue}/mes`
    if (cartExtras) cartExtras.textContent = `${format_number(extrasMonthly)} ${currencyValue}/mes`
    if (cartAnnual) {
        cartAnnual.textContent = isYear
            ? `Un solo pago desde ${format_number(Math.round((baseMonthly + extrasMonthly) * 12 * global_toogle_price.annual_discount))} ${currencyValue}`
            : ""
    }
    if (cartBuy) {
        const baseLink = global_toogle_price.plan_links[global_toogle_price.selected_plan] || "#"
        const message = build_cart_message(planLabel, agents, users, channels, extraConversations)
        cartBuy.href = baseLink.includes("?text=")
            ? `${baseLink.split("?text=")[0]}?text=${encodeURIComponent(message)}`
            : baseLink
    }
}

function build_cart_message(planLabel, agents, users, channels, extraConversations) {
    const extrasParts = []
    if (agents > 0) extrasParts.push(`${agents} agente(s) IA extra`)
    if (users > 0) extrasParts.push(`${users} usuario(s) extra`)
    if (channels > 0) extrasParts.push(`${channels} canal(es) extra`)
    if (extraConversations > 0) extrasParts.push(`${format_number(extraConversations)} conversaciones extra`)
    const extrasText = extrasParts.length ? ` Extras: ${extrasParts.join(", ")}.` : ""
    return `Me interesa el plan ${planLabel} de easycontact.${extrasText}`
}

function setup_cart_visibility() {
    const cart = document.getElementById("floating_cart")
    const section = document.getElementById("Precios-dir")
    if (!cart || !section) return
    const show = (visible) => {
        cart.classList.toggle("hidden", !visible)
    }
    if ("IntersectionObserver" in window) {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach((entry) => show(entry.isIntersecting))
        }, { threshold: 0.2 })
        observer.observe(section)
        return
    }
    const onScroll = () => {
        const rect = section.getBoundingClientRect()
        const visible = rect.top < window.innerHeight * 0.8 && rect.bottom > window.innerHeight * 0.2
        show(visible)
    }
    window.addEventListener("scroll", onScroll, { passive: true })
    onScroll()
}

function get_addon_prices() {
    if (global_toogle_price.currency.select.key === "USD") {
        return global_toogle_price.addons_usd
    }
    const rate = global_toogle_price.base_monthly.BOB.price_startup / global_toogle_price.base_monthly.USD.price_startup
    return {
        agent: Math.round(global_toogle_price.addons_usd.agent * rate),
        user: Math.round(global_toogle_price.addons_usd.user * rate),
        channel: Math.round(global_toogle_price.addons_usd.channel * rate),
        conv_block: Math.round(global_toogle_price.addons_usd.conv_block * rate),
        conv_block_size: global_toogle_price.addons_usd.conv_block_size
    }
}

function to_int(value) {
    const parsed = parseInt(value, 10)
    return Number.isNaN(parsed) || parsed < 0 ? 0 : parsed
}

function to_delta(value) {
    const parsed = parseInt(value, 10)
    return Number.isNaN(parsed) ? 0 : parsed
}

function format_number(value) {
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
}

function toggle_dropdown_price() {
    document.getElementById('dropdown_price').classList.toggle('hidden');
}

function select_option(flag_src, key, value) {
    document.getElementById('selected_flag').src = flag_src;
    document.getElementById('selected_text').textContent = key;
    document.getElementById('dropdown_price').classList.add('hidden');
    global_toogle_price.currency.select.key = key
    global_toogle_price.currency.select.value = value
    toogle_price(global_toogle_price.price.select)
}
