class Destination {

  final String name;
  final String image;
  final String location;

  Destination({
    required this.name,
    required this.image,
    required this.location,
  });

}

List<Destination> destinations = [

  Destination(
    name: "Munnar",
    image: "assets/images/munnar.jpg",
    location: "Idukki",
  ),

  Destination(
    name: "Alleppey",
    image: "assets/images/alleppey.jpg",
    location: "Alappuzha",
  ),

  Destination(
    name: "Kochi",
    image: "assets/images/kochi.jpg",
    location: "Ernakulam",
  ),

  Destination(
    name: "Wayanad",
    image: "assets/images/wayanad.jpg",
    location: "Wayanad",
  ),

];