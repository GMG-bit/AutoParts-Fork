import os
import sys
import coverage

try:
    from django.core.management import call_command
    import django
except ModuleNotFoundError:
    print("Error: Django no está instalado en el intérprete actual.")
    req_path = os.path.join(os.getcwd(), "requirements.txt")
    if os.path.exists(req_path):
        with open(req_path, "r", encoding="utf-8") as f:
            reqs = f.read().lower()
        if "django" not in reqs:
            print("Advertencia: 'django' no aparece en requirements.txt.")
    print("\nSugerencias:")
    print("1) Crear y activar virtualenv (PowerShell):")
    print("   python -m venv .venv")
    print("   Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force")
    print("   .\\.venv\\Scripts\\Activate.ps1")
    print("   o en cmd: .\\.venv\\Scripts\\activate")
    print("2) Instalar dependencias:")
    print("   pip install -r requirements.txt")
    print("3) Ejecutar de nuevo: python run_all_tests.py")
    sys.exit(1)

# Configurar entorno Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "AutoParts.settings")
django.setup()

print("=" * 45)
print("Iniciando pruebas unitarias del proyecto AutoParts")
print("=" * 45)

# Inicializar medidor de cobertura
cov = coverage.Coverage()
cov.start()

try:
    # Permite pasar apps o tests concretos como argumentos:
    # Ejemplo: python run_all_tests.py api
    args = sys.argv[1:]
    if args:
        print(f"Ejecutando pruebas con argumentos: {args}")
    else:
        print("Ejecutando todas las pruebas (sin argumentos)...")
    call_command("test", *args, verbosity=2)
finally:
    cov.stop()
    cov.save()

print("\n" + "=" * 45)
print("📊 Reporte de cobertura del código")
print("=" * 45)
cov.report(show_missing=True)

# Generar reporte HTML visual
html_path = os.path.join(os.getcwd(), "htmlcov")
try:
    cov.html_report(directory=html_path)
    print(f"\n✅ Reporte HTML generado en: {html_path}")
except Exception as e:
    print(f"No se pudo generar reporte HTML: {e}")
