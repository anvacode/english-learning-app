import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lesson.dart';
import '../models/lesson_category.dart';
import '../models/lesson_exercise.dart';
import '../models/lesson_item.dart';
import '../models/lesson_level.dart';

/// Carga lecciones desde JSON con fallback a datos hardcodeados.
Future<List<Lesson>> loadLessonsFromJson() async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/lessons.json');
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final lessonsJson = jsonData['lessons'] as List<dynamic>;

    return lessonsJson.map((lessonJson) => _parseLesson(lessonJson)).toList();
  } catch (e) {
    debugPrint('⚠️ Error cargando lessons.json, usando datos locales: $e');
    return lessonsList;
  }
}

Lesson _parseLesson(Map<String, dynamic> json) {
  final itemsJson = json['items'] as List<dynamic>? ?? [];
  final exercisesJson = json['exercises'] as List<dynamic>? ?? [];

  return Lesson(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    question: json['question'] ?? '',
    items: itemsJson.map((item) => _parseLessonItem(item)).toList(),
    exercises: exercisesJson.map((ex) => _parseLessonExercise(ex)).toList(),
  );
}

LessonItem _parseLessonItem(Map<String, dynamic> json) {
  Color? color;
  final colorStr = json['stimulusColor'] as String?;
  if (colorStr != null) {
    color = _colorFromString(colorStr);
  }

  return LessonItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    stimulusColor: color,
    stimulusImageAsset: json['stimulusImageAsset'],
    stimulusText: json['stimulusText'],
    options: (json['options'] as List<dynamic>?)?.cast<String>() ?? [],
    correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
  );
}

LessonExercise _parseLessonExercise(Map<String, dynamic> json) {
  final typeStr = json['type'] as String? ?? 'multipleChoice';
  return LessonExercise(type: _exerciseTypeFromString(typeStr));
}

ExerciseType _exerciseTypeFromString(String type) {
  switch (type) {
    case 'multipleChoice':
      return ExerciseType.multipleChoice;
    case 'matching':
      return ExerciseType.matching;
    case 'spelling':
      return ExerciseType.spelling;
    case 'listening':
      return ExerciseType.listening;
    case 'speaking':
      return ExerciseType.speaking;
    default:
      return ExerciseType.multipleChoice;
  }
}

Color _colorFromString(String colorStr) {
  switch (colorStr.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'grey':
    case 'gray':
      return Colors.grey;
    default:
      return Colors.grey;
  }
}

/// Datos offline de lecciones educativas para la app de inglés.
/// Lecciones tipo: asociación visual + selección múltiple.
final List<Lesson> lessonsList = [
  Lesson(
    id: 'colors',
    title: 'Colores',
    question: '¿Qué color es este?',
    items: [
      LessonItem(
        id: 'red',
        title: 'Red',
        stimulusColor: Colors.red,
        options: ['red', 'blue', 'green'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'blue',
        title: 'Blue',
        stimulusColor: Colors.blue,
        options: ['red', 'blue', 'green'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'green',
        title: 'Green',
        stimulusColor: Colors.green,
        options: ['green', 'yellow', 'purple'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'yellow',
        title: 'Yellow',
        stimulusColor: Colors.yellow,
        options: ['yellow', 'purple', 'pink'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'black',
        title: 'Black',
        stimulusColor: Colors.black,
        options: ['black', 'white', 'gray'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'white',
        title: 'White',
        stimulusColor: Colors.white,
        options: ['white', 'black', 'gray'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'orange',
        title: 'Orange',
        stimulusColor: Colors.orange,
        options: ['purple', 'orange', 'brown'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'purple',
        title: 'Purple',
        stimulusColor: Colors.purple,
        options: ['orange', 'purple', 'pink'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'pink',
        title: 'Pink',
        stimulusColor: Colors.pink,
        options: ['blue', 'pink', 'red'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'brown',
        title: 'Brown',
        stimulusColor: Colors.brown,
        options: ['brown', 'orange', 'black'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [LessonExercise(type: ExerciseType.multipleChoice)],
  ),
  Lesson(
    id: 'fruits',
    title: 'Frutas',
    question: '¿Qué fruta es esta?',
    items: [
      LessonItem(
        id: 'apple',
        title: 'Apple',
        stimulusImageAsset: 'assets/images/fruits/apple.jpg',
        options: ['apple', 'banana', 'orange'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'banana',
        title: 'Banana',
        stimulusImageAsset: 'assets/images/fruits/banana.jpg',
        options: ['banana', 'apple', 'strawberry'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'orange',
        title: 'Orange',
        stimulusImageAsset: 'assets/images/fruits/orange.jpg',
        options: ['orange', 'apple', 'lemon'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'strawberry',
        title: 'Strawberry',
        stimulusImageAsset: 'assets/images/fruits/strawberry.jpg',
        options: ['strawberry', 'cherry', 'apple'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'grapes',
        title: 'Grapes',
        stimulusImageAsset: 'assets/images/fruits/grapes.jpg',
        options: ['grapes', 'blueberry', 'banana'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'pineapple',
        title: 'Pineapple',
        stimulusImageAsset: 'assets/images/fruits/pineapple.jpg',
        options: ['pineapple', 'banana', 'mango'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'watermelon',
        title: 'Watermelon',
        stimulusImageAsset: 'assets/images/fruits/watermelon.jpg',
        options: ['watermelon', 'apple', 'orange'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'pear',
        title: 'Pear',
        stimulusImageAsset: 'assets/images/fruits/pear.jpg',
        options: ['pear', 'apple', 'peach'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      // Spelling movido a sección de Práctica
    ],
  ),
  Lesson(
    id: 'animals',
    title: 'Animales',
    question: '¿Qué animal es este?',
    items: [
      LessonItem(
        id: 'dog',
        title: 'Dog',
        stimulusImageAsset: 'assets/images/animals/dog.jpg',
        options: ['dog', 'cat', 'horse'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'cat',
        title: 'Cat',
        stimulusImageAsset: 'assets/images/animals/cat.jpg',
        options: ['cat', 'dog', 'bird'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'cow',
        title: 'Cow',
        stimulusImageAsset: 'assets/images/animals/cow.jpg',
        options: ['cow', 'horse', 'pig'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'chicken',
        title: 'Chicken',
        stimulusImageAsset: 'assets/images/animals/chicken.jpg',
        options: ['chicken', 'duck', 'bird'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'horse',
        title: 'Horse',
        stimulusImageAsset: 'assets/images/animals/horse.jpg',
        options: ['horse', 'cow', 'donkey'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'elephant',
        title: 'Elephant',
        stimulusImageAsset: 'assets/images/animals/elephant.jpg',
        options: ['elephant', 'hippo', 'cow'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'bird',
        title: 'Bird',
        stimulusImageAsset: 'assets/images/animals/bird.jpg',
        options: ['bird', 'chicken', 'fish'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'fish',
        title: 'Fish',
        stimulusImageAsset: 'assets/images/animals/fish.jpg',
        options: ['fish', 'bird', 'snake'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
      // Spelling movido a sección de Práctica
    ],
  ),
  Lesson(
    id: 'classroom',
    title: 'Objetos del aula',
    question: '¿Qué objeto es este?',
    items: [
      LessonItem(
        id: 'book',
        title: 'Libro',
        stimulusImageAsset: 'assets/images/classroom/book.jpg',
        options: ['book', 'notebook', 'pencil'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'pencil',
        title: 'Lápiz',
        stimulusImageAsset: 'assets/images/classroom/pencil.jpg',
        options: ['pencil', 'eraser', 'ruler'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'chair',
        title: 'Silla',
        stimulusImageAsset: 'assets/images/classroom/chair.jpg',
        options: ['chair', 'table', 'backpack'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'table',
        title: 'Mesa',
        stimulusImageAsset: 'assets/images/classroom/table.jpg',
        options: ['table', 'chair', 'notebook'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'notebook',
        title: 'Cuaderno',
        stimulusImageAsset: 'assets/images/classroom/notebook.jpg',
        options: ['notebook', 'book', 'pencil'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'backpack',
        title: 'Mochila',
        stimulusImageAsset: 'assets/images/classroom/backpack.jpg',
        options: ['backpack', 'chair', 'table'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'eraser',
        title: 'Borrador',
        stimulusImageAsset: 'assets/images/classroom/eraser.jpg',
        options: ['eraser', 'pencil', 'ruler'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'ruler',
        title: 'Regla',
        stimulusImageAsset: 'assets/images/classroom/ruler.jpg',
        options: ['ruler', 'eraser', 'pencil'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [LessonExercise(type: ExerciseType.multipleChoice)],
  ),
  Lesson(
    id: 'family_1',
    title: 'Familia',
    question: '¿Qué miembro de la familia es este?',
    items: [
      LessonItem(
        id: 'mother',
        title: 'Mother',
        stimulusImageAsset: 'assets/images/family/mother.jpg',
        options: ['mother', 'father', 'sister'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'father',
        title: 'Father',
        stimulusImageAsset: 'assets/images/family/father.jpg',
        options: ['father', 'mother', 'brother'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'brother',
        title: 'Brother',
        stimulusImageAsset: 'assets/images/family/brother.jpg',
        options: ['brother', 'sister', 'father'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'sister',
        title: 'Sister',
        stimulusImageAsset: 'assets/images/family/sister.jpg',
        options: ['sister', 'brother', 'mother'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'grandfather',
        title: 'Grandfather',
        stimulusImageAsset: 'assets/images/family/grandfather.jpg',
        options: ['grandfather', 'grandmother', 'father'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'grandmother',
        title: 'Grandmother',
        stimulusImageAsset: 'assets/images/family/grandmother.jpg',
        options: ['grandmother', 'grandfather', 'mother'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'family',
        title: 'Family',
        stimulusImageAsset: 'assets/images/family/family.jpg',
        options: ['family', 'father', 'mother'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),
  Lesson(
    id: 'numbers',
    title: 'Números',
    question: '¿Qué número es este?',
    items: [
      LessonItem(
        id: 'one',
        title: 'One',
        stimulusImageAsset: 'assets/images/numbers/one.jpg',
        options: ['one', 'two', 'three'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'two',
        title: 'Two',
        stimulusImageAsset: 'assets/images/numbers/two.jpg',
        options: ['two', 'one', 'four'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'three',
        title: 'Three',
        stimulusImageAsset: 'assets/images/numbers/three.jpg',
        options: ['three', 'two', 'five'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'four',
        title: 'Four',
        stimulusImageAsset: 'assets/images/numbers/four.jpg',
        options: ['four', 'three', 'six'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'five',
        title: 'Five',
        stimulusImageAsset: 'assets/images/numbers/five.jpg',
        options: ['five', 'four', 'seven'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'six',
        title: 'Six',
        stimulusImageAsset: 'assets/images/numbers/six.jpg',
        options: ['six', 'five', 'eight'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'seven',
        title: 'Seven',
        stimulusImageAsset: 'assets/images/numbers/seven.jpg',
        options: ['seven', 'six', 'nine'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'eight',
        title: 'Eight',
        stimulusImageAsset: 'assets/images/numbers/eight.jpg',
        options: ['eight', 'seven', 'ten'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'nine',
        title: 'Nine',
        stimulusImageAsset: 'assets/images/numbers/nine.jpg',
        options: ['nine', 'eight', 'ten'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'ten',
        title: 'Ten',
        stimulusImageAsset: 'assets/images/numbers/ten.jpg',
        options: ['ten', 'nine', 'eight'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),
  Lesson(
    id: 'body_parts',
    title: 'Partes del cuerpo',
    question: '¿Qué parte del cuerpo es esta?',
    items: [
      LessonItem(
        id: 'head',
        title: 'Head',
        stimulusImageAsset: 'assets/images/body_parts/head.jpg',
        options: ['head', 'hand', 'foot'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'eye',
        title: 'Eye',
        stimulusImageAsset: 'assets/images/body_parts/eye.jpg',
        options: ['eye', 'ear', 'nose'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'nose',
        title: 'Nose',
        stimulusImageAsset: 'assets/images/body_parts/nose.jpg',
        options: ['nose', 'mouth', 'eye'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'mouth',
        title: 'Mouth',
        stimulusImageAsset: 'assets/images/body_parts/mouth.jpg',
        options: ['mouth', 'nose', 'ear'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'hand',
        title: 'Hand',
        stimulusImageAsset: 'assets/images/body_parts/hand.jpg',
        options: ['hand', 'foot', 'arm'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'foot',
        title: 'Foot',
        stimulusImageAsset: 'assets/images/body_parts/foot.jpg',
        options: ['foot', 'hand', 'leg'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'arm',
        title: 'Arm',
        stimulusImageAsset: 'assets/images/body_parts/arm.jpg',
        options: ['arm', 'leg', 'hand'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'leg',
        title: 'Leg',
        stimulusImageAsset: 'assets/images/body_parts/leg.jpg',
        options: ['leg', 'arm', 'foot'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'ear',
        title: 'Ear',
        stimulusImageAsset: 'assets/images/body_parts/ear.jpg',
        options: ['ear', 'eye', 'nose'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'hair',
        title: 'Hair',
        stimulusImageAsset: 'assets/images/body_parts/hair.jpg',
        options: ['hair', 'head', 'eye'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),
  Lesson(
    id: 'clothes',
    title: 'Ropa',
    question: '¿Qué prenda es esta?',
    items: [
      LessonItem(
        id: 'shirt',
        title: 'Shirt',
        stimulusImageAsset: 'assets/images/clothes/shirt.jpg',
        options: ['shirt', 'pants', 'dress'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'pants',
        title: 'Pants',
        stimulusImageAsset: 'assets/images/clothes/pants.jpg',
        options: ['pants', 'shirt', 'shoes'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'dress',
        title: 'Dress',
        stimulusImageAsset: 'assets/images/clothes/dress.jpg',
        options: ['dress', 'shirt', 'skirt'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'shoes',
        title: 'Shoes',
        stimulusImageAsset: 'assets/images/clothes/shoes.jpg',
        options: ['shoes', 'socks', 'hat'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'hat',
        title: 'Hat',
        stimulusImageAsset: 'assets/images/clothes/hat.jpg',
        options: ['hat', 'cap', 'shoes'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'socks',
        title: 'Socks',
        stimulusImageAsset: 'assets/images/clothes/socks.jpg',
        options: ['socks', 'shoes', 'pants'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'jacket',
        title: 'Jacket',
        stimulusImageAsset: 'assets/images/clothes/jacket.jpg',
        options: ['jacket', 'shirt', 'coat'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'skirt',
        title: 'Skirt',
        stimulusImageAsset: 'assets/images/clothes/skirt.jpg',
        options: ['skirt', 'dress', 'pants'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),
  Lesson(
    id: 'food_drinks',
    title: 'Comida y bebidas',
    question: '¿Qué es esto?',
    items: [
      LessonItem(
        id: 'bread',
        title: 'Bread',
        stimulusImageAsset: 'assets/images/food/bread.jpg',
        options: ['bread', 'cake', 'cookie'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'milk',
        title: 'Milk',
        stimulusImageAsset: 'assets/images/food/milk.jpg',
        options: ['milk', 'water', 'juice'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'water',
        title: 'Water',
        stimulusImageAsset: 'assets/images/food/water.jpg',
        options: ['water', 'milk', 'juice'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'egg',
        title: 'Egg',
        stimulusImageAsset: 'assets/images/food/egg.jpg',
        options: ['egg', 'bread', 'cheese'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'cheese',
        title: 'Cheese',
        stimulusImageAsset: 'assets/images/food/cheese.jpg',
        options: ['cheese', 'egg', 'butter'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'rice',
        title: 'Rice',
        stimulusImageAsset: 'assets/images/food/rice.jpg',
        options: ['rice', 'bread', 'pasta'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'juice',
        title: 'Juice',
        stimulusImageAsset: 'assets/images/food/juice.jpg',
        options: ['juice', 'water', 'milk'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'cake',
        title: 'Cake',
        stimulusImageAsset: 'assets/images/food/cake.jpg',
        options: ['cake', 'cookie', 'bread'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'cookie',
        title: 'Cookie',
        stimulusImageAsset: 'assets/images/food/cookie.jpg',
        options: ['cookie', 'cake', 'bread'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),
  Lesson(
    id: 'actions',
    title: 'Acciones',
    question: '¿Qué acción es esta?',
    items: [
      LessonItem(
        id: 'run',
        title: 'Run',
        stimulusImageAsset: 'assets/images/actions/run.jpg',
        options: ['run', 'walk', 'jump'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'jump',
        title: 'Jump',
        stimulusImageAsset: 'assets/images/actions/jump.jpg',
        options: ['jump', 'run', 'sit'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'eat',
        title: 'Eat',
        stimulusImageAsset: 'assets/images/actions/eat.jpg',
        options: ['eat', 'drink', 'sleep'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'sleep',
        title: 'Sleep',
        stimulusImageAsset: 'assets/images/actions/sleep.jpg',
        options: ['sleep', 'eat', 'wake'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'walk',
        title: 'Walk',
        stimulusImageAsset: 'assets/images/actions/walk.jpg',
        options: ['walk', 'run', 'stand'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'sit',
        title: 'Sit',
        stimulusImageAsset: 'assets/images/actions/sit.jpg',
        options: ['sit', 'stand', 'jump'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'stand',
        title: 'Stand',
        stimulusImageAsset: 'assets/images/actions/stand.jpg',
        options: ['stand', 'sit', 'walk'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'drink',
        title: 'Drink',
        stimulusImageAsset: 'assets/images/actions/drink.jpg',
        options: ['drink', 'eat', 'run'],
        correctAnswerIndex: 0,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // ============================================================================
  // NIVEL INTERMEDIO - 10 LECCIONES
  // ============================================================================

  // Lesson 11: Daily Routines
  Lesson(
    id: 'daily_routines',
    title: 'Rutinas Diarias',
    question: '¿Qué acción es esta?',
    items: [
      LessonItem(
        id: 'wake_up',
        title: 'Wake up',
        stimulusImageAsset: 'assets/images/routines/wake_up.jpg',
        options: ['wake up', 'sleep', 'eat'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'brush_teeth',
        title: 'Brush teeth',
        stimulusImageAsset: 'assets/images/routines/brush_teeth.jpg',
        options: ['wash hands', 'brush teeth', 'comb hair'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'take_shower',
        title: 'Take a shower',
        stimulusImageAsset: 'assets/images/routines/take_shower.jpg',
        options: ['take a shower', 'get dressed', 'go to bed'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'get_dressed',
        title: 'Get dressed',
        stimulusImageAsset: 'assets/images/routines/get_dressed.jpg',
        options: ['wake up', 'get dressed', 'eat breakfast'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'eat_breakfast',
        title: 'Eat breakfast',
        stimulusImageAsset: 'assets/images/routines/eat_breakfast.jpg',
        options: ['eat breakfast', 'eat lunch', 'eat dinner'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'go_to_school',
        title: 'Go to school',
        stimulusImageAsset: 'assets/images/routines/go_to_school.jpg',
        options: ['go to school', 'go home', 'go to bed'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'do_homework',
        title: 'Do homework',
        stimulusImageAsset: 'assets/images/routines/do_homework.jpg',
        options: ['play games', 'do homework', 'watch TV'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'go_to_bed',
        title: 'Go to bed',
        stimulusImageAsset: 'assets/images/routines/go_to_bed.jpg',
        options: ['wake up', 'go to bed', 'take a shower'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 12: Weather & Seasons
  Lesson(
    id: 'weather_seasons',
    title: 'Clima y Estaciones',
    question: '¿Qué clima o estación es?',
    items: [
      LessonItem(
        id: 'sunny',
        title: 'Sunny',
        stimulusImageAsset: 'assets/images/weather/sunny.jpg',
        options: ['sunny', 'rainy', 'cloudy'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'rainy',
        title: 'Rainy',
        stimulusImageAsset: 'assets/images/weather/rainy.jpg',
        options: ['sunny', 'rainy', 'snowy'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'cloudy',
        title: 'Cloudy',
        stimulusImageAsset: 'assets/images/weather/cloudy.jpg',
        options: ['cloudy', 'windy', 'sunny'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'snowy',
        title: 'Snowy',
        stimulusImageAsset: 'assets/images/weather/snowy.jpg',
        options: ['rainy', 'snowy', 'sunny'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'windy',
        title: 'Windy',
        stimulusImageAsset: 'assets/images/weather/windy.jpg',
        options: ['windy', 'sunny', 'rainy'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'spring',
        title: 'Spring',
        stimulusImageAsset: 'assets/images/weather/spring.jpg',
        options: ['spring', 'summer', 'winter'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'summer',
        title: 'Summer',
        stimulusImageAsset: 'assets/images/weather/summer.jpg',
        options: ['winter', 'summer', 'fall'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'fall',
        title: 'Fall',
        stimulusImageAsset: 'assets/images/weather/fall.jpg',
        options: ['fall', 'spring', 'winter'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'winter',
        title: 'Winter',
        stimulusImageAsset: 'assets/images/weather/winter.jpg',
        options: ['summer', 'winter', 'spring'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 13: Occupations
  Lesson(
    id: 'occupations',
    title: 'Profesiones',
    question: '¿Qué profesión es esta?',
    items: [
      LessonItem(
        id: 'doctor',
        title: 'Doctor',
        stimulusImageAsset: 'assets/images/occupations/doctor.jpg',
        options: ['doctor', 'nurse', 'teacher'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'teacher',
        title: 'Teacher',
        stimulusImageAsset: 'assets/images/occupations/teacher.jpg',
        options: ['student', 'teacher', 'doctor'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'firefighter',
        title: 'Firefighter',
        stimulusImageAsset: 'assets/images/occupations/firefighter.jpg',
        options: ['firefighter', 'police officer', 'doctor'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'police_officer',
        title: 'Police officer',
        stimulusImageAsset: 'assets/images/occupations/police_officer.jpg',
        options: ['firefighter', 'police officer', 'soldier'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'nurse',
        title: 'Nurse',
        stimulusImageAsset: 'assets/images/occupations/nurse.jpg',
        options: ['nurse', 'doctor', 'dentist'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'chef',
        title: 'Chef',
        stimulusImageAsset: 'assets/images/occupations/chef.jpg',
        options: ['waiter', 'chef', 'baker'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'pilot',
        title: 'Pilot',
        stimulusImageAsset: 'assets/images/occupations/pilot.jpg',
        options: ['pilot', 'astronaut', 'driver'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'dentist',
        title: 'Dentist',
        stimulusImageAsset: 'assets/images/occupations/dentist.jpg',
        options: ['doctor', 'dentist', 'nurse'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 14: Transportation
  Lesson(
    id: 'transportation',
    title: 'Transporte',
    question: '¿Qué medio de transporte es?',
    items: [
      LessonItem(
        id: 'car',
        title: 'Car',
        stimulusImageAsset: 'assets/images/transportation/car.jpg',
        options: ['car', 'bus', 'truck'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'bus',
        title: 'Bus',
        stimulusImageAsset: 'assets/images/transportation/bus.jpg',
        options: ['car', 'bus', 'train'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'train',
        title: 'Train',
        stimulusImageAsset: 'assets/images/transportation/train.jpg',
        options: ['train', 'subway', 'bus'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'airplane',
        title: 'Airplane',
        stimulusImageAsset: 'assets/images/transportation/airplane.jpg',
        options: ['helicopter', 'airplane', 'rocket'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'bicycle',
        title: 'Bicycle',
        stimulusImageAsset: 'assets/images/transportation/bicycle.jpg',
        options: ['bicycle', 'motorcycle', 'scooter'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'boat',
        title: 'Boat',
        stimulusImageAsset: 'assets/images/transportation/boat.jpg',
        options: ['ship', 'boat', 'yacht'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'motorcycle',
        title: 'Motorcycle',
        stimulusImageAsset: 'assets/images/transportation/motorcycle.jpg',
        options: ['motorcycle', 'bicycle', 'scooter'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'helicopter',
        title: 'Helicopter',
        stimulusImageAsset: 'assets/images/transportation/helicopter.jpg',
        options: ['airplane', 'helicopter', 'drone'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 15: Places in City
  Lesson(
    id: 'places_city',
    title: 'Lugares de la Ciudad',
    question: '¿Qué lugar es este?',
    items: [
      LessonItem(
        id: 'hospital',
        title: 'Hospital',
        stimulusImageAsset: 'assets/images/places/hospital.jpg',
        options: ['hospital', 'school', 'library'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'school',
        title: 'School',
        stimulusImageAsset: 'assets/images/places/school.jpg',
        options: ['hospital', 'school', 'library'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'park',
        title: 'Park',
        stimulusImageAsset: 'assets/images/places/park.jpg',
        options: ['park', 'zoo', 'beach'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'supermarket',
        title: 'Supermarket',
        stimulusImageAsset: 'assets/images/places/supermarket.jpg',
        options: ['restaurant', 'supermarket', 'bakery'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'library',
        title: 'Library',
        stimulusImageAsset: 'assets/images/places/library.jpg',
        options: ['library', 'museum', 'school'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'restaurant',
        title: 'Restaurant',
        stimulusImageAsset: 'assets/images/places/restaurant.jpg',
        options: ['cafe', 'restaurant', 'bakery'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'bank',
        title: 'Bank',
        stimulusImageAsset: 'assets/images/places/bank.jpg',
        options: ['bank', 'post office', 'hospital'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'museum',
        title: 'Museum',
        stimulusImageAsset: 'assets/images/places/museum.jpg',
        options: ['library', 'museum', 'theater'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 16: Food & Meals
  Lesson(
    id: 'meals',
    title: 'Comidas',
    question: '¿Qué comida o momento del día es?',
    items: [
      LessonItem(
        id: 'breakfast',
        title: 'Breakfast',
        stimulusImageAsset: 'assets/images/meals/breakfast.jpg',
        options: ['breakfast', 'lunch', 'dinner'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'lunch',
        title: 'Lunch',
        stimulusImageAsset: 'assets/images/meals/lunch.jpg',
        options: ['breakfast', 'lunch', 'snack'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'dinner',
        title: 'Dinner',
        stimulusImageAsset: 'assets/images/meals/dinner.jpg',
        options: ['lunch', 'dinner', 'breakfast'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'snack',
        title: 'Snack',
        stimulusImageAsset: 'assets/images/meals/snack.jpg',
        options: ['snack', 'meal', 'dessert'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'pizza',
        title: 'Pizza',
        stimulusImageAsset: 'assets/images/meals/pizza.jpg',
        options: ['pizza', 'pasta', 'sandwich'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'sandwich',
        title: 'Sandwich',
        stimulusImageAsset: 'assets/images/meals/sandwich.jpg',
        options: ['burger', 'sandwich', 'hot dog'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'soup',
        title: 'Soup',
        stimulusImageAsset: 'assets/images/meals/soup.jpg',
        options: ['soup', 'salad', 'stew'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'salad',
        title: 'Salad',
        stimulusImageAsset: 'assets/images/meals/salad.jpg',
        options: ['soup', 'salad', 'vegetables'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 17: Clothing & Accessories
  Lesson(
    id: 'clothing_extended',
    title: 'Ropa y Accesorios',
    question: '¿Qué prenda o accesorio es?',
    items: [
      LessonItem(
        id: 'coat',
        title: 'Coat',
        stimulusImageAsset: 'assets/images/clothing_ext/coat.jpg',
        options: ['coat', 'jacket', 'sweater'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'sweater',
        title: 'Sweater',
        stimulusImageAsset: 'assets/images/clothing_ext/sweater.jpg',
        options: ['shirt', 'sweater', 'jacket'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'gloves',
        title: 'Gloves',
        stimulusImageAsset: 'assets/images/clothing_ext/gloves.jpg',
        options: ['gloves', 'mittens', 'socks'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'scarf',
        title: 'Scarf',
        stimulusImageAsset: 'assets/images/clothing_ext/scarf.jpg',
        options: ['belt', 'scarf', 'tie'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'boots',
        title: 'Boots',
        stimulusImageAsset: 'assets/images/clothing_ext/boots.jpg',
        options: ['boots', 'shoes', 'sandals'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'sunglasses',
        title: 'Sunglasses',
        stimulusImageAsset: 'assets/images/clothing_ext/sunglasses.jpg',
        options: ['glasses', 'sunglasses', 'goggles'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'belt',
        title: 'Belt',
        stimulusImageAsset: 'assets/images/clothing_ext/belt.jpg',
        options: ['belt', 'strap', 'tie'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'umbrella',
        title: 'Umbrella',
        stimulusImageAsset: 'assets/images/clothing_ext/umbrella.jpg',
        options: ['hat', 'umbrella', 'raincoat'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 18: Emotions & Feelings
  Lesson(
    id: 'emotions',
    title: 'Emociones',
    question: '¿Qué emoción es esta?',
    items: [
      LessonItem(
        id: 'happy',
        title: 'Happy',
        stimulusImageAsset: 'assets/images/emotions/happy.jpg',
        options: ['happy', 'sad', 'excited'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'sad',
        title: 'Sad',
        stimulusImageAsset: 'assets/images/emotions/sad.jpg',
        options: ['happy', 'sad', 'angry'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'angry',
        title: 'Angry',
        stimulusImageAsset: 'assets/images/emotions/angry.jpg',
        options: ['angry', 'tired', 'scared'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'excited',
        title: 'Excited',
        stimulusImageAsset: 'assets/images/emotions/excited.jpg',
        options: ['happy', 'excited', 'surprised'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'scared',
        title: 'Scared',
        stimulusImageAsset: 'assets/images/emotions/scared.jpg',
        options: ['scared', 'worried', 'nervous'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'tired',
        title: 'Tired',
        stimulusImageAsset: 'assets/images/emotions/tired.jpg',
        options: ['sleepy', 'tired', 'bored'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'surprised',
        title: 'Surprised',
        stimulusImageAsset: 'assets/images/emotions/surprised.jpg',
        options: ['surprised', 'shocked', 'confused'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'proud',
        title: 'Proud',
        stimulusImageAsset: 'assets/images/emotions/proud.jpg',
        options: ['happy', 'proud', 'confident'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
      // Spelling movido a sección de Práctica
    ],
  ),

  // Lesson 19: School Subjects
  Lesson(
    id: 'school_subjects',
    title: 'Materias Escolares',
    question: '¿Qué materia es esta?',
    items: [
      LessonItem(
        id: 'math',
        title: 'Math',
        stimulusImageAsset: 'assets/images/subjects/math.jpg',
        options: ['math', 'science', 'english'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'science',
        title: 'Science',
        stimulusImageAsset: 'assets/images/subjects/science.jpg',
        options: ['math', 'science', 'biology'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'history',
        title: 'History',
        stimulusImageAsset: 'assets/images/subjects/history.jpg',
        options: ['history', 'geography', 'social studies'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'art',
        title: 'Art',
        stimulusImageAsset: 'assets/images/subjects/art.jpg',
        options: ['music', 'art', 'drama'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'music',
        title: 'Music',
        stimulusImageAsset: 'assets/images/subjects/music.jpg',
        options: ['music', 'art', 'dance'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'physical_education',
        title: 'Physical Education',
        stimulusImageAsset: 'assets/images/subjects/pe.jpg',
        options: ['sports', 'physical education', 'gym'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'english',
        title: 'English',
        stimulusImageAsset: 'assets/images/subjects/english.jpg',
        options: ['english', 'reading', 'writing'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'geography',
        title: 'Geography',
        stimulusImageAsset: 'assets/images/subjects/geography.jpg',
        options: ['history', 'geography', 'social studies'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 20: Hobbies & Sports
  Lesson(
    id: 'hobbies_sports',
    title: 'Pasatiempos y Deportes',
    question: '¿Qué actividad es esta?',
    items: [
      LessonItem(
        id: 'soccer',
        title: 'Soccer',
        stimulusImageAsset: 'assets/images/sports/soccer.jpg',
        options: ['soccer', 'football', 'basketball'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'basketball',
        title: 'Basketball',
        stimulusImageAsset: 'assets/images/sports/basketball.jpg',
        options: ['soccer', 'basketball', 'baseball'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'swimming',
        title: 'Swimming',
        stimulusImageAsset: 'assets/images/sports/swimming.jpg',
        options: ['swimming', 'diving', 'surfing'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'painting',
        title: 'Painting',
        stimulusImageAsset: 'assets/images/sports/painting.jpg',
        options: ['drawing', 'painting', 'coloring'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'reading',
        title: 'Reading',
        stimulusImageAsset: 'assets/images/sports/reading.jpg',
        options: ['reading', 'writing', 'studying'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'dancing',
        title: 'Dancing',
        stimulusImageAsset: 'assets/images/sports/dancing.jpg',
        options: ['singing', 'dancing', 'acting'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'cycling',
        title: 'Cycling',
        stimulusImageAsset: 'assets/images/sports/cycling.jpg',
        options: ['cycling', 'running', 'skating'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'singing',
        title: 'Singing',
        stimulusImageAsset: 'assets/images/sports/singing.jpg',
        options: ['dancing', 'singing', 'playing instrument'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // ============================================================================
  // NIVEL AVANZADO - 8 LECCIONES
  // ============================================================================

  // Lesson 21: Verb Tenses (Present & Past)
  Lesson(
    id: 'verb_tenses',
    title: 'Tiempos Verbales',
    question: '¿Qué acción representa esta imagen?',
    items: [
      LessonItem(
        id: 'running',
        title: 'I am running',
        stimulusImageAsset: 'assets/images/verbs/running.jpg',
        options: ['I am running', 'I run', 'I ran'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'ate',
        title: 'I ate',
        stimulusImageAsset: 'assets/images/verbs/ate.jpg',
        options: ['I eat', 'I am eating', 'I ate'],
        correctAnswerIndex: 2,
      ),
      LessonItem(
        id: 'playing',
        title: 'He is playing',
        stimulusImageAsset: 'assets/images/verbs/playing.jpg',
        options: ['He plays', 'He is playing', 'He played'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'studied',
        title: 'She studied',
        stimulusImageAsset: 'assets/images/verbs/studied.jpg',
        options: ['She studies', 'She studied', 'She is studying'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'swimming',
        title: 'They are swimming',
        stimulusImageAsset: 'assets/images/verbs/swimming.jpg',
        options: ['They swim', 'They are swimming', 'They swam'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'walked',
        title: 'We walked',
        stimulusImageAsset: 'assets/images/verbs/walked.jpg',
        options: ['We walk', 'We walked', 'We are walking'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'reading_now',
        title: 'I am reading',
        stimulusImageAsset: 'assets/images/verbs/reading_now.jpg',
        options: ['I read', 'I am reading', 'I will read'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'cooked',
        title: 'She cooked',
        stimulusImageAsset: 'assets/images/verbs/cooked.jpg',
        options: ['She cooks', 'She is cooking', 'She cooked'],
        correctAnswerIndex: 2,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 22: Prepositions
  Lesson(
    id: 'prepositions',
    title: 'Preposiciones',
    question: '¿Dónde está el objeto?',
    items: [
      LessonItem(
        id: 'in',
        title: 'In the box',
        stimulusImageAsset: 'assets/images/prepositions/in.jpg',
        options: ['in the box', 'on the box', 'under the box'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'on',
        title: 'On the table',
        stimulusImageAsset: 'assets/images/prepositions/on.jpg',
        options: ['under the table', 'on the table', 'next to the table'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'under',
        title: 'Under the bed',
        stimulusImageAsset: 'assets/images/prepositions/under.jpg',
        options: ['under the bed', 'on the bed', 'in the bed'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'between',
        title: 'Between the chairs',
        stimulusImageAsset: 'assets/images/prepositions/between.jpg',
        options: [
          'next to the chairs',
          'between the chairs',
          'behind the chairs',
        ],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'next_to',
        title: 'Next to the door',
        stimulusImageAsset: 'assets/images/prepositions/next_to.jpg',
        options: [
          'next to the door',
          'behind the door',
          'in front of the door',
        ],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'behind',
        title: 'Behind the tree',
        stimulusImageAsset: 'assets/images/prepositions/behind.jpg',
        options: [
          'in front of the tree',
          'behind the tree',
          'next to the tree',
        ],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'in_front_of',
        title: 'In front of the house',
        stimulusImageAsset: 'assets/images/prepositions/in_front.jpg',
        options: [
          'in front of the house',
          'behind the house',
          'inside the house',
        ],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'above',
        title: 'Above the clouds',
        stimulusImageAsset: 'assets/images/prepositions/above.jpg',
        options: ['under the clouds', 'above the clouds', 'in the clouds'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),

  // Lesson 23: Adjectives & Opposites
  Lesson(
    id: 'adjectives_opposites',
    title: 'Adjetivos y Opuestos',
    question: '¿Qué describe esta imagen?',
    items: [
      LessonItem(
        id: 'big',
        title: 'Big',
        stimulusImageAsset: 'assets/images/adjectives/big.jpg',
        options: ['big', 'small', 'medium'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'small',
        title: 'Small',
        stimulusImageAsset: 'assets/images/adjectives/small.jpg',
        options: ['big', 'small', 'tiny'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'hot',
        title: 'Hot',
        stimulusImageAsset: 'assets/images/adjectives/hot.jpg',
        options: ['hot', 'cold', 'warm'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'cold',
        title: 'Cold',
        stimulusImageAsset: 'assets/images/adjectives/cold.jpg',
        options: ['hot', 'cold', 'cool'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'fast',
        title: 'Fast',
        stimulusImageAsset: 'assets/images/adjectives/fast.jpg',
        options: ['fast', 'slow', 'quick'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'slow',
        title: 'Slow',
        stimulusImageAsset: 'assets/images/adjectives/slow.jpg',
        options: ['fast', 'slow', 'steady'],
        correctAnswerIndex: 1,
      ),
      LessonItem(
        id: 'tall',
        title: 'Tall',
        stimulusImageAsset: 'assets/images/adjectives/tall.jpg',
        options: ['tall', 'short', 'high'],
        correctAnswerIndex: 0,
      ),
      LessonItem(
        id: 'short',
        title: 'Short',
        stimulusImageAsset: 'assets/images/adjectives/short.jpg',
        options: ['tall', 'short', 'low'],
        correctAnswerIndex: 1,
      ),
    ],
    exercises: const [
      LessonExercise(type: ExerciseType.multipleChoice),
      LessonExercise(type: ExerciseType.matching),
    ],
  ),
];

/// Niveles educativos agrupando lecciones por dificultad.
final List<LessonLevel> lessonLevels = [
  LessonLevel(
    id: 'beginner',
    title: 'Principiante',
    lessons: [
      lessonsList[0], // Colors
      lessonsList[1], // Fruits
      lessonsList[2], // Animals
      lessonsList[3], // Classroom Objects
      lessonsList[4], // Family
      lessonsList[5], // Numbers
      lessonsList[6], // Body Parts
      lessonsList[7], // Clothes
      lessonsList[8], // Food and Drinks
      lessonsList[9], // Actions
    ],
  ),
  LessonLevel(
    id: 'intermediate',
    title: 'Intermedio',
    lessons: [
      lessonsList[10], // Daily Routines
      lessonsList[11], // Weather & Seasons
      lessonsList[12], // Occupations
      lessonsList[13], // Transportation
      lessonsList[14], // Places in City
      lessonsList[15], // Food & Meals
      lessonsList[16], // Clothing Extended
      lessonsList[17], // Emotions
      lessonsList[18], // School Subjects
      lessonsList[19], // Hobbies & Sports
    ],
  ),
  LessonLevel(
    id: 'advanced',
    title: 'Avanzado',
    lessons: [
      lessonsList[20], // Verb Tenses
      lessonsList[21], // Prepositions
      lessonsList[22], // Adjectives & Opposites
    ],
  ),
];

/// Categorías de lecciones agrupadas temáticamente.
final List<LessonCategory> lessonCategories = [
  LessonCategory(
    id: 'colors',
    title: 'Colors',
    description: 'Learn English color names through visual association',
    lessons: lessonsList,
  ),
];

/// ============================================================================
/// LISTA DE IMÁGENES JPG REQUERIDAS
/// ============================================================================
///
/// Total: 220 imágenes JPG (Colors usa stimulusColor, no imágenes)
///
/// ========== NIVEL PRINCIPIANTE (76 imágenes) ==========
/// FRUITS (8): apple.jpg, banana.jpg, orange.jpg, strawberry.jpg, grapes.jpg,
///             pineapple.jpg, watermelon.jpg, pear.jpg
/// ANIMALS (8): dog.jpg, cat.jpg, cow.jpg, chicken.jpg, horse.jpg, elephant.jpg,
///              bird.jpg, fish.jpg
/// CLASSROOM (8): book.jpg, pencil.jpg, chair.jpg, table.jpg, notebook.jpg,
///                backpack.jpg, eraser.jpg, ruler.jpg
/// FAMILY (7): mother.jpg, father.jpg, brother.jpg, sister.jpg, grandfather.jpg,
///             grandmother.jpg, family.jpg
/// NUMBERS (10): one.jpg, two.jpg, three.jpg, four.jpg, five.jpg, six.jpg,
///               seven.jpg, eight.jpg, nine.jpg, ten.jpg
/// BODY_PARTS (10): head.jpg, eye.jpg, nose.jpg, mouth.jpg, hand.jpg, foot.jpg,
///                  arm.jpg, leg.jpg, ear.jpg, hair.jpg
/// CLOTHES (8): shirt.jpg, pants.jpg, dress.jpg, shoes.jpg, hat.jpg, socks.jpg,
///              jacket.jpg, skirt.jpg
/// FOOD_DRINKS (9): bread.jpg, milk.jpg, water.jpg, egg.jpg, cheese.jpg, rice.jpg,
///                  juice.jpg, cake.jpg, cookie.jpg
/// ACTIONS (8): run.jpg, jump.jpg, eat.jpg, sleep.jpg, walk.jpg, sit.jpg,
///              stand.jpg, drink.jpg
///
/// ========== NIVEL INTERMEDIO (80 imágenes) ==========
/// ROUTINES (8): wake_up.jpg, brush_teeth.jpg, take_shower.jpg, get_dressed.jpg,
///               eat_breakfast.jpg, go_to_school.jpg, do_homework.jpg, go_to_bed.jpg
/// WEATHER (9): sunny.jpg, rainy.jpg, cloudy.jpg, snowy.jpg, windy.jpg, spring.jpg,
///              summer.jpg, fall.jpg, winter.jpg
/// OCCUPATIONS (8): doctor.jpg, teacher.jpg, firefighter.jpg, police_officer.jpg,
///                  nurse.jpg, chef.jpg, pilot.jpg, dentist.jpg
/// TRANSPORTATION (8): car.jpg, bus.jpg, train.jpg, airplane.jpg, bicycle.jpg,
///                     boat.jpg, motorcycle.jpg, helicopter.jpg
/// PLACES (8): hospital.jpg, school.jpg, park.jpg, supermarket.jpg, library.jpg,
///             restaurant.jpg, bank.jpg, museum.jpg
/// MEALS (8): breakfast.jpg, lunch.jpg, dinner.jpg, snack.jpg, pizza.jpg,
///            sandwich.jpg, soup.jpg, salad.jpg
/// CLOTHING_EXT (8): coat.jpg, sweater.jpg, gloves.jpg, scarf.jpg, boots.jpg,
///                   sunglasses.jpg, belt.jpg, umbrella.jpg
/// EMOTIONS (8): happy.jpg, sad.jpg, angry.jpg, excited.jpg, scared.jpg,
///               tired.jpg, surprised.jpg, proud.jpg
/// SUBJECTS (8): math.jpg, science.jpg, history.jpg, art.jpg, music.jpg, pe.jpg,
///               english.jpg, geography.jpg
/// SPORTS (8): soccer.jpg, basketball.jpg, swimming.jpg, painting.jpg, reading.jpg,
///             dancing.jpg, cycling.jpg, singing.jpg
///
/// ========== NIVEL AVANZADO (64 imágenes) ==========
/// VERBS (8): running.jpg, ate.jpg, playing.jpg, studied.jpg, swimming.jpg,
///            walked.jpg, reading_now.jpg, cooked.jpg
/// PREPOSITIONS (8): in.jpg, on.jpg, under.jpg, between.jpg, next_to.jpg,
///                   behind.jpg, in_front.jpg, above.jpg
/// ADJECTIVES (8): big.jpg, small.jpg, hot.jpg, cold.jpg, fast.jpg, slow.jpg,
///                 tall.jpg, short.jpg
/// QUESTIONS (8): who.jpg, what.jpg, where.jpg, when.jpg, why.jpg, how.jpg,
///                which.jpg, whose.jpg
/// CONVERSATIONS (8): hello.jpg, goodbye.jpg, thank_you.jpg, please.jpg,
///                    excuse_me.jpg, how_are_you.jpg, help.jpg, welcome.jpg
/// NUMBERS_ADV (8): eleven.jpg, fifteen.jpg, twenty.jpg, thirty.jpg, fifty.jpg,
///                  seventy.jpg, ninety.jpg, hundred.jpg
/// TIME (8): morning.jpg, afternoon.jpg, night.jpg, monday.jpg, friday.jpg,
///           january.jpg, today.jpg, tomorrow.jpg
/// HEALTH (8): heart.jpg, stomach.jpg, brain.jpg, wash_hands.jpg, exercise.jpg,
///             healthy_food.jpg, drink_water.jpg, sleep_well.jpg
///
/// Estructura de carpetas:
/// assets/images/
/// ├── colors/          (no usa imágenes, solo stimulusColor)
/// ├── fruits/          (8)
/// ├── animals/         (8)
/// ├── classroom/       (8)
/// ├── family/          (7)
/// ├── numbers/         (10)
/// ├── body_parts/      (10)
/// ├── clothes/         (8)
/// ├── food/            (9)
/// ├── actions/         (8)
/// ├── routines/        (8) ← INTERMEDIO
/// ├── weather/         (9)
/// ├── occupations/     (8)
/// ├── transportation/  (8)
/// ├── places/          (8)
/// ├── meals/           (8)
/// ├── clothing_ext/    (8)
/// ├── emotions/        (8)
/// ├── subjects/        (8)
/// ├── sports/          (8)
/// ├── verbs/           (8) ← AVANZADO
/// ├── prepositions/    (8)
/// ├── adjectives/      (8)
/// ├── questions/       (8)
/// ├── conversations/   (8)
/// ├── numbers_adv/     (8)
/// ├── time/            (8)
/// └── health/          (8)
/// ============================================================================
