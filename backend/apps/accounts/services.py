CAPABILITY_PERMISSION_MAP = {
    "can_view_inventory": "inventory.view_inventory",
    "can_view_zero_stock": "inventory.view_zero_stock",
    "can_create_stock_receipt": "inventory.create_stock_receipt",
    "can_restock": "inventory.restock",
    "can_deactivate_rims": "inventory.deactivate_rims",
    "can_create_sale": "sales.create_sale",
    "can_view_sales": "sales.view_sales",
    "can_view_sale_detail": "sales.view_sale_detail",
}


def compute_capabilities(user):
    if not user or not user.is_authenticated:
        return {key: False for key in CAPABILITY_PERMISSION_MAP}
    return {key: user.has_perm(permission) for key, permission in CAPABILITY_PERMISSION_MAP.items()}
