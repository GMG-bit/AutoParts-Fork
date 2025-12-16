# === ETAPA 1: BUILDER y PRUEBAS ===
# Usamos una imagen base con Python
FROM python:3.11-slim as builder

# Configuramos el entorno
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# Copiamos solo el archivo de requerimientos para aprovechar el cache de Docker
COPY requirements.txt .

# Instalamos dependencias
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copiamos el resto del código fuente
COPY . .

# Comando de prueba que GitHub Actions ejecutará (Asegúrate de tener un script 'run_tests.sh' o similar)
# Por ejemplo, puedes cambiar esto por RUN python manage.py test o RUN pytest
# En este ejemplo, solo preparamos la imagen para el paso de pruebas en el workflow.

# === ETAPA 2: PRODUCCIÓN (FINAL) ===
# Imagen final más limpia y pequeña
FROM python:3.11-slim

# Configuramos el entorno de producción
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# Copiamos las dependencias y el código desde la etapa 'builder'
# Esto asegura que solo se copian los archivos esenciales y no las herramientas de desarrollo
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/src/app /usr/src/app

# Opcional: Si usas una base de datos, podrías necesitar instalar 'psycopg2-binary' o 'mysqlclient' en la etapa final si no están ya en requirements.txt

# Exponemos el puerto de Django
EXPOSE 8000

# Comando para correr la aplicación
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "nombre_de_tu_proyecto.wsgi:application"]
# NOTA: Reemplaza "nombre_de_tu_proyecto" con el nombre de tu directorio de proyecto Django principal.