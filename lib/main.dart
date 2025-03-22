import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

dynamic database;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database = await openDatabase(
    path.join(await getDatabasesPath(), "ToDoListDB.db"),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''CREATE TABLE Task(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          description TEXT,
          date TEXT,
          isDone INTEGER
        )''');
    },
  );
  runApp(const MainApp());
}

//Insert Operation
Future insertTask(ToDoListModelClass obj) async {
  final localDB = await database;

  await localDB.insert(
    "Task",
    obj.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

//Retrive Operation
Future<List<ToDoListModelClass>> getTask() async {
  final localDB = await database;
  List<Map<String, dynamic>> taskList = await localDB.query("Task");

  return List.generate(taskList.length, (index) {
    return ToDoListModelClass(
      id: taskList[index]['id'],
      title: taskList[index]['title'],
      description: taskList[index]['description'],
      date: taskList[index]['date'],
      isDone: taskList[index]['isDone'] == 1,
    );
  });
}

//Delete Operation
Future deleteTask(int id) async {
  final localDB = await database;

  await localDB.delete(
    "Task",
    where: "id = ? ",
    whereArgs: [id],
  );
}

//Update Operation
Future updateTask(ToDoListModelClass obj) async {
  final localDB = await database;

  await localDB.update(
    "Task",
    obj.toMap(),
    where: "id = ? ",
    whereArgs: [obj.id],
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ToDoApp(),
    );
  }
}

///MODEL CLASS
class ToDoListModelClass {
  int? id;
  String? title;
  String? description;
  String? date;
  bool isDone;

  ToDoListModelClass({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'isDone': isDone ? 1 : 0,
    };
  }

  @override
  String toString() {
    return '{id:$id,title:$title,description:$description,date:$date,isDone:$isDone}';
  }
}

class ToDoApp extends StatefulWidget {
  const ToDoApp({super.key});

  @override
  State createState() => _ToDoAppState();
}

class _ToDoAppState extends State {
  //CONTROLLERS
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  //Global keys
  final GlobalKey<FormFieldState> _titleKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _descriptionKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _dateKey = GlobalKey<FormFieldState>();

  List cardList = [];

  Future refreshList() async {
    final List<ToDoListModelClass> tasks = await getTask();
    setState(() {
      cardList = tasks;
    });

    print(await getTask());
  }

  @override
  void initState() {
    super.initState();
    refreshList();
  }

  String getGreeting() {
    var time = DateTime.now().hour;

    if (time < 12) {
      return " Good Morning ";
    } else if (time < 18) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  void submit(bool doEdit, [ToDoListModelClass? toDoModelobj]) async {
    if (_titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _dateController.text.isNotEmpty) {
      if (!doEdit) {
        setState(() {
          insertTask(ToDoListModelClass(
              title: _titleController.text,
              description: _descriptionController.text,
              date: _dateController.text));
          refreshList();
          showSnackbar("Task added successfully");
        });
      } else {
        setState(() {
          toDoModelobj!.title = _titleController.text.trim();
          toDoModelobj.description = _descriptionController.text.trim();
          toDoModelobj.date = _dateController.text.trim();
          updateTask(toDoModelobj);
          refreshList();
          showSnackbar("Task updated successfully");
        });
      }
    } else {
      return;
    }
    clearData();
    Navigator.of(context).pop();
  }

  //Clear the Controllers
  void clearData() {
    _titleController.clear();
    _descriptionController.clear();
    _dateController.clear();
  }

  //Edit The Card
  void editCard(ToDoListModelClass toDoModelobj) {
    _titleController.text = toDoModelobj.title!;
    _descriptionController.text = toDoModelobj.description!;
    _dateController.text = toDoModelobj.date!;

    viewBottomSheet(true, toDoModelobj);
  }

  //Delete the Card
  void deleteCard(ToDoListModelClass toDoModelobj) async {
    setState(() {
      deleteTask(toDoModelobj.id!);
      showSnackbar("Task deleted successfully");
    });
    refreshList();
  }

  /// Dispose method to clean up resources when the widget is disposed.
  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
  }

  // Function to show Snackbar
  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color.fromRGBO(89, 74, 241, 1),
        content: Text(
          message,
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color.fromRGBO(255, 255, 255, 1),
          ),
        ),
      ),
    );
  }

  Future<void> viewBottomSheet(bool doEdit,
      [ToDoListModelClass? toDoModelobj]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 15,
              ),
              Text(
                "Create To-Do",
                style: GoogleFonts.quicksand(
                  color: const Color.fromRGBO(0, 0, 0, 1),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Title",
                      style: GoogleFonts.quicksand(
                        color: const Color.fromRGBO(89, 57, 241, 1),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextFormField(
                      controller: _titleController,
                      key: _titleKey,
                      decoration: InputDecoration(
                        hintText: 'Enter Title',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(89, 74, 241, 1),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(89, 74, 241, 1),
                            width: 0.5,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      // cursorHeight: 15,
                      validator: (valueKey) {
                        if (valueKey == null || valueKey.isEmpty) {
                          return 'Please enter title';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Description",
                      style: GoogleFonts.quicksand(
                        color: const Color.fromRGBO(89, 57, 241, 1),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      key: _descriptionKey,
                      decoration: InputDecoration(
                        hintText: 'Enter Description',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(89, 74, 241, 1),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(89, 74, 241, 1),
                            width: 0.5,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      // cursorHeight: 15,
                      validator: (valueKey) {
                        if (valueKey == null || valueKey.isEmpty) {
                          return 'Please enter title';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Date",
                      style: GoogleFonts.quicksand(
                        color: const Color.fromRGBO(89, 57, 241, 1),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextFormField(
                      controller: _dateController,
                      key: _dateKey,
                      decoration: InputDecoration(
                        hintText: 'Enter Date',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(89, 74, 241, 1),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(89, 74, 241, 1),
                            width: 0.5,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2025),
                            );

                            String formatedDate =
                                DateFormat.yMMMd().format(pickedDate!);

                            setState(
                              () {
                                _dateController.text = formatedDate;
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            size: 25,
                            color: Color.fromRGBO(0, 0, 0, 0.7),
                          ),
                        ),
                      ),
                      readOnly: true,
                      validator: (valueKey) {
                        if (valueKey == null || valueKey.isEmpty) {
                          return 'Please enter title';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 50,
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              //  bool titleKeyValidated =
                              _titleKey.currentState!.validate();
                              //  bool descriptionKeyValidate =
                              _descriptionKey.currentState!.validate();
                              //  bool dateKeyValidated =
                              _dateKey.currentState!.validate();

                              // if (titleKeyValidated &&
                              //     descriptionKeyValidate &&
                              //     dateKeyValidated) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     SnackBar(
                              //       backgroundColor:
                              //           const Color.fromRGBO(89, 74, 241, 1),
                              //       content: Text(
                              //         "Card added Successfully !!!",
                              //         style: GoogleFonts.quicksand(
                              //           fontSize: 14,
                              //           fontWeight: FontWeight.w500,
                              //           color: const Color.fromRGBO(
                              //               255, 255, 255, 1),
                              //         ),
                              //       ),
                              //     ),
                              //   );
                              // }
                              doEdit
                                  ? submit(doEdit, toDoModelobj)
                                  : submit(doEdit);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(89, 57, 241, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Submit",
                              style: GoogleFonts.inter(
                                color: const Color.fromRGBO(255, 255, 255, 1),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(111, 81, 255, 1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 30,
              horizontal: 20,
            ),
            child: Column(
              children: [
                Text(
                  getGreeting(),
                  style: GoogleFonts.quicksand(
                    color: const Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  "Jayprakash",
                  style: GoogleFonts.quicksand(
                    color: const Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(217, 217, 217, 1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Text(
                      "CREATE TO DO LIST",
                      style: GoogleFonts.quicksand(
                        color: const Color.fromRGBO(0, 0, 0, 1),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 30,
                      ),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(38),
                          topRight: Radius.circular(38),
                        ),
                      ),
                      child: ListView.builder(
                          itemCount: cardList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Slidable(
                              closeOnScroll: true,
                              endActionPane: ActionPane(
                                extentRatio: 0.2,
                                motion: const DrawerMotion(),
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        const Spacer(),

                                        ///Gesture Detector for Edit
                                        GestureDetector(
                                          onTap: () {
                                            editCard(cardList[index]);
                                          },
                                          child: Container(
                                            height: 40,
                                            width: 40,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  89, 57, 241, 1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),

                                        ///Gesture Detector for Delete
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              deleteCard(cardList[index]);
                                            });
                                          },
                                          child: Container(
                                            height: 40,
                                            width: 40,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  89, 57, 241, 1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.only(
                                    top: 20, left: 20, bottom: 20),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: const BoxDecoration(
                                    color: Color.fromRGBO(255, 255, 255, 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.08),
                                        blurRadius: 20,
                                        spreadRadius: 0,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                    borderRadius:
                                        BorderRadius.all(Radius.zero)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 58,
                                          width: 58,
                                          // padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromRGBO(
                                                217, 217, 217, 1),
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              "assets/task.png",
                                              height: 42,
                                              width: 42,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cardList[index].title,
                                                style: GoogleFonts.inter(
                                                  color: const Color.fromRGBO(
                                                      0, 0, 0, 1),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 9,
                                              ),
                                              Text(
                                                cardList[index].description,
                                                style: GoogleFonts.inter(
                                                  color: const Color.fromRGBO(
                                                      0, 0, 0, 0.7),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 9,
                                              ),
                                              Text(
                                                cardList[index].date,
                                                style: GoogleFonts.inter(
                                                  color: const Color.fromRGBO(
                                                      0, 0, 0, 0.7),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        ///CheckBox
                                        Checkbox(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          value: cardList[index].isDone,
                                          activeColor: Colors.green,
                                          onChanged: (value) {
                                            // Toggle the isDone status
                                            setState(() {
                                              cardList[index].isDone = value!;
                                              updateTask(cardList[index]);
                                              refreshList();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 46,
        width: 46,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: const Color.fromRGBO(111, 81, 255, 1),
          onPressed: () async {
            clearData();
            await viewBottomSheet(false);
            refreshList();
          },
          tooltip: 'Add Card',
          child: const Icon(
            Icons.add,
            size: 36,
            color: Color.fromRGBO(255, 255, 255, 1),
            shadows: [
              Shadow(
                  color: Color.fromRGBO(0, 0, 0, .3),
                  blurRadius: 3,
                  offset: Offset(0, 0)),
            ],
          ),
        ),
      ),
    );
  }
}
