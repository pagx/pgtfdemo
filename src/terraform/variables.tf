locals {
   pgtfbuild-datestamp = "${formatdate("YYYYMMDD", "${timestamp()}")}"
   buildby_tag = "PG"

   la_name = "pgtfdemoLA"
   sa_name = "pgtfdemoSA"
   asp_name = "pgtfdemo_asp"


   sa_types = ["blob", "file", "queue", "table"]

   private_dns_zones = {
    la = {
        name = "privatelink.azurewebsites.net"
    },
    blob = {
        name = "privatelink.blob.core.windows.net"
    },
    file = {
        name = "privatelink.file.core.windows.net"
    },
    queue = {
        name = "privatelink.queue.core.windows.net"
    },
    table = {
        name = "privatelink.table.core.windows.net"
    }
   }
}
variable location {
  type = string
}
variable application_name {
  type = string
}
variable environment_name {
  type = string
}
