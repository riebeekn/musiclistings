resource "render_project" "this" {
  name = "TML"
  environments = {
    "default" : {
      name : "default",
      protected_status : "protected"
    }
  }
}
