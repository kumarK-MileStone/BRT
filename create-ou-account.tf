resource "aws_organizations_account" "account" {
  name      = "${var.account_name}"
  email     = "${var.account_owner_email}"
  role_name = "${var.account_role}"
}

resource "aws_organizations_organizational_unit" "ou" {
  name      = "${var.ou_name}"
  parent_id = "${var.ou_id}"
}