terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

resource "yandex_iam_service_account" "zombicide-sa" {
  name      = "zombicide-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "zombicide-sa-uploader" {
  role      = "storage.uploader"
  member    = "serviceAccount:${yandex_iam_service_account.zombicide-sa.id}"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "zombicide-sa-viewer" {
  role      = "storage.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.zombicide-sa.id}"
  folder_id = var.folder_id
}

resource "yandex_storage_bucket" "zombicide-app-bucket" {
  bucket = "zombicide-app-bucket"
  max_size = 1073741824
}

resource "yandex_storage_object" "zombicide-mount-path" {
  bucket = "zombicide-app-bucket"
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
      bucket = "zombicide-app-bucket"
      prefix = ""
    }
  }
}

