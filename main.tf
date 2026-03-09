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

resource "yandex_resourcemanager_folder_iam_member" "zombicide-sa-storage-uploader" {
  role      = "storage.uploader"
  member    = "serviceAccount:${yandex_iam_service_account.zombicide-sa.id}"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "zombicide-sa-storage-viewer" {
  role      = "storage.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.zombicide-sa.id}"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "zombicide-sa-registry-puller" {
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.zombicide-sa.id}"
  folder_id = var.folder_id
}

resource "yandex_iam_service_account_static_access_key" "zombicide-sa-static-key" {
  service_account_id = yandex_iam_service_account.sombicide-sa.id
}

resource "yandex_storage_bucket" "zombicide-app-bucket" {
  access_key = yandex_iam_service_account_static_access_key.zombicide-sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.zombicide-sa-static-key.secret_key
  bucket     = "zombicide-app-bucket"
  max_size   = 1073741824
  folder_id  = var.folder_id
}

resource "yandex_storage_object" "zombicide-mount-path" {
  bucket  = "zombicide-app-bucket"
  key     = "app/saves/"
  content = ""
}

resource "yandex_serverless_container" "zombicide-app" {
  name               = "zombicide-app"
  memory             = 512
  cores              = 2
  service_account_id = yandex_iam_service_account.zombicide-sa.id
  image {
    url = "cr.yandex/crpc043hc46bmegqv1dm/zombicide-app:${var.image_tag}"
  }
  mounts {
    mount_point_path = "/app/saves"
    mode             = "rw"
    object_storage {
      bucket  = "zombicide-app-bucket"
    }
  }
}

