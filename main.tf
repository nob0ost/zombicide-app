terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

resource "yandex_iam_service_account" "zombicide-sa" {
  name      = "zombicide-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "zombicide-sa-uploader" {
  role      = "storage.uploader"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "zombicide-sa-viewer" {
  role      = "storage.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.zombicide-sa.id}"
}

resource "yandex_storage_bucket" "zombicide-app-bucket" {
  bucket = "zombicide-app-bucket"
  max_size = 1073741824
}

resource "yandex_storage_object" "zombicide-mount-path" {
  bucket = yandex_storage_bucket.zombicide-app-bucket.name
  key    = "/app/saves"
}

resource "yandex_serverless_container" "zombicide-app" {
  name               = "zombicide-app"
  memory             = 512
  cores              = 2
  image {
    url = "cr.yandex/crpc043hc46bmegqv1dm/zombicide-app:${var.image_tag}"
  }
  mounts {
    mount_point_path = "/app/saves"
    mode             = "rw"
    object_storage {
      bucket = yandex_storage_bucket.zombicide-app-bucket.name
      prefix = ""
    }
  }
}

