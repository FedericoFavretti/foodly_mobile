import 'models/local_model.dart';
import 'models/plato_model.dart';
import 'models/direccion_model.dart';

/// Catálogo de demostración alineado al dominio backend hasta que CU-CL04/05 estén listos.
const mockLocales = [
  LocalModel(
    id: 1,
    nombre: 'Burger House',
    descripcion: 'Hamburguesas artesanales y papas crocantes.',
    calificacionGlobal: 4.6,
    estaAbierto: true,
    imagenes: [],
    direccion: DireccionModel(
      calle: 'Av. 18 de Julio',
      numero: '1200',
      ciudad: 'Montevideo',
    ),
  ),
  LocalModel(
    id: 2,
    nombre: 'Pizza Napoli',
    descripcion: 'Pizzas a la piedra y pastas caseras.',
    calificacionGlobal: 4.3,
    estaAbierto: true,
    imagenes: [],
    direccion: DireccionModel(
      calle: 'Bvar. Artigas',
      numero: '450',
      ciudad: 'Montevideo',
    ),
  ),
  LocalModel(
    id: 3,
    nombre: 'Sushi MVD',
    descripcion: 'Rolls frescos y combos para compartir.',
    calificacionGlobal: 4.8,
    estaAbierto: false,
    imagenes: [],
    direccion: DireccionModel(
      calle: 'Rambla República',
      numero: '3000',
      ciudad: 'Montevideo',
    ),
  ),
  LocalModel(
    id: 4,
    nombre: 'La Milanesa',
    descripcion: 'Milanesas gigantes al horno o fritas.',
    calificacionGlobal: 4.1,
    estaAbierto: true,
    imagenes: [],
    direccion: DireccionModel(
      calle: 'Av. Italia',
      numero: '2200',
      ciudad: 'Montevideo',
    ),
  ),
];

const mockPlatos = [
  PlatoModel(
    id: 101,
    nombre: 'Clásica con cheddar',
    descripcion: 'Medallón de carne, cheddar y salsa especial.',
    precio: 420,
    imagenes: [],
    disponible: true,
    localId: 1,
  ),
  PlatoModel(
    id: 102,
    nombre: 'Doble bacon',
    descripcion: 'Doble carne, bacon crocante y cebolla caramelizada.',
    precio: 520,
    imagenes: [],
    disponible: true,
    localId: 1,
  ),
  PlatoModel(
    id: 201,
    nombre: 'Muzzarella',
    descripcion: 'Salsa de tomate, muzzarella y orégano.',
    precio: 480,
    imagenes: [],
    disponible: true,
    localId: 2,
  ),
  PlatoModel(
    id: 202,
    nombre: 'Fugazzeta',
    descripcion: 'Cebolla, muzzarella y aceitunas verdes.',
    precio: 510,
    imagenes: [],
    disponible: false,
    localId: 2,
  ),
  PlatoModel(
    id: 301,
    nombre: 'Roll California',
    descripcion: 'Cangrejo, palta y pepino.',
    precio: 390,
    imagenes: [],
    disponible: true,
    localId: 3,
  ),
  PlatoModel(
    id: 401,
    nombre: 'Milanesa napolitana',
    descripcion: 'Con jamón, muzzarella y salsa de tomate.',
    precio: 450,
    imagenes: [],
    disponible: true,
    localId: 4,
  ),
];
