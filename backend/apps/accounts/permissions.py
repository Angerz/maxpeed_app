from rest_framework.permissions import BasePermission


class DjangoPermissionRequired(BasePermission):
    required_permission = None

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.has_perm(self.required_permission)


class CanViewInventory(DjangoPermissionRequired):
    required_permission = "inventory.view_inventory"


class CanViewZeroStock(DjangoPermissionRequired):
    required_permission = "inventory.view_zero_stock"


class CanCreateStockReceipt(DjangoPermissionRequired):
    required_permission = "inventory.create_stock_receipt"


class CanRestock(DjangoPermissionRequired):
    required_permission = "inventory.restock"


class CanDeactivateRims(DjangoPermissionRequired):
    required_permission = "inventory.deactivate_rims"


class CanCreateSale(DjangoPermissionRequired):
    required_permission = "sales.create_sale"


class CanViewSales(DjangoPermissionRequired):
    required_permission = "sales.view_sales"


class CanViewSaleDetail(DjangoPermissionRequired):
    required_permission = "sales.view_sale_detail"
