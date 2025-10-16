from django.test import TestCase
from .models import ClienteDistribuidor # <-- Corregido: Importamos el modelo que sí existe

class ClienteDistribuidorModelTest(TestCase):
    """
    Pruebas para el modelo ClienteDistribuidor.
    """
    def test_crear_cliente(self):
        """
        Prueba que se puede crear un cliente y su nombre es correcto.
        """
        # Creamos una instancia del modelo ClienteDistribuidor
        cliente = ClienteDistribuidor.objects.create(nombre='Cliente de Prueba', tipo='cliente')

        # Buscamos el cliente que acabamos de crear en la base de datos
        cliente_guardado = ClienteDistribuidor.objects.get(id=cliente.id)

        # Comprobamos (Assert) que el nombre guardado es el que esperamos
        self.assertEqual(cliente_guardado.nombre, 'Cliente de Prueba')