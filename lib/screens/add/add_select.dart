import 'package:flutter/material.dart';
import 'add_screen.dart';
import '../../globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/firebase_functions.dart';

class AddSelect extends StatefulWidget {
  @override
  State<AddSelect> createState() => _AddSelectState();
}

class _AddSelectState extends State<AddSelect> {
  late List<Map<String, dynamic>> title_filenames_fs;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getSetsList().then((setsList) {
      setState(() {
        title_filenames_fs = setsList;
        isLoading = false;
      });
    });
    // firebaseInit(globals.title_filenames);
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
          appBar: AppBar(title: const Text("Add"), scrolledUnderElevation: 0.2),
          body: Center(child: CircularProgressIndicator()),
        )
        : Scaffold(
          appBar: AppBar(title: const Text("Add"), scrolledUnderElevation: 0.2),
          body: ListView.builder(
            itemCount: title_filenames_fs.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: Color(0xFFDDFFDD)),
                  child: ListTile(
                    key: ValueKey(title_filenames_fs[index]["filename"]),
                    dense: true,
                    minVerticalPadding: 28,
                    contentPadding: EdgeInsets.symmetric(horizontal: 48),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title_filenames_fs[index]["title"].toString(),
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          updatedAtTrans(
                            title_filenames_fs[index]['updatedAt'].toString(),
                          ),
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AddScreen(
                                title_filename: title_filenames_fs[index],
                              ),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                  ),
                ),
              );
            },
          ),
        );
  }
}
