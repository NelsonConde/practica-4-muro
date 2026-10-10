variable "proyecto" {
  type        = string
  description = "Identificador del proyecto de Google Cloud"
}

variable "prefijo" {
  type        = string
  description = "Prefijo de nombres: minúsculas, empieza por letra, entre 4 y 20 caracteres"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,19}$", var.prefijo))
    error_message = "El prefijo debe empezar por letra, usar solo minúsculas, números y guiones, y tener entre 4 y 20 caracteres."
  }
}

variable "region" {
  type    = string
  default = "us-central1"
}
