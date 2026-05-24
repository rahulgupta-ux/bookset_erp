import '../models/book_item.dart';

final Map<String, Map<String, List<BookItem>>> schoolData = {
  "DPS": {
    "Class 8": [
      BookItem(
        subject: "Mathematics",
        price: 500,
        image: "https://picsum.photos/id/101/200",
      ),

      BookItem(
        subject: "Science",
        price: 600,
        image: "https://picsum.photos/id/102/200",
      ),

      BookItem(
        subject: "English",
        price: 450,
        image: "https://picsum.photos/id/103/200",
      ),

      BookItem(
        subject: "SST",
        price: 550,
        image: "https://picsum.photos/id/104/200",
      ),
    ],

    "Class 10": [
      BookItem(
        subject: "Physics",
        price: 700,
        image: "https://picsum.photos/id/110/200",
      ),

      BookItem(
        subject: "Chemistry",
        price: 650,
        image: "https://picsum.photos/id/106/200",
      ),

      BookItem(
        subject: "Maths",
        price: 750,
        image: "https://picsum.photos/id/107/200",
      ),
    ],
  },

  "Green Valley": {
    "Class 6": [
      BookItem(
        subject: "Math",
        price: 400,
        image: "https://picsum.photos/id/101/200",
      ),

      BookItem(
        subject: "English",
        price: 350,
        image: "https://picsum.photos/id/108/200",
      ),

      BookItem(
        subject: "Science",
        price: 500,
        image: "https://picsum.photos/id/109/200",
      ),
    ],
  },
};
