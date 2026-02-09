import 'package:flutter/material.dart';
import 'flashcard_screen.dart';
import '../../globals.dart' as globals;
import '../../utils/functions.dart';

class FlashCardSelect extends StatefulWidget {
  @override
  State<FlashCardSelect> createState() => _FlashCardSelectState();
}

class _FlashCardSelectState extends State<FlashCardSelect> {
  //////////////////
  ///// 変数定義 /////
  //////////////////
  List<Map<String, String>> title_filenames = globals.title_filenames;
  globals.QuizOrder selectedOrder = globals.currentOrder;

  ////////////////////////
  ///// ライフサイクル /////
  ///////////////////////

  /////////////////////
  //////// UI ////////
  ////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcard"),
        scrolledUnderElevation: 0.2,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16), // 右端に隙間
            child: DropdownButton<globals.QuizOrder>(
              value: globals.currentOrder,
              underline: SizedBox(),
              dropdownColor: Colors.grey[100],
              icon: SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    globals.currentOrder = value;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                  value: globals.QuizOrder.original,
                  child: Text('default'),
                ),
                DropdownMenuItem(
                  value: globals.QuizOrder.wrongFirst,
                  child: Text('mistakes'),
                ),
                DropdownMenuItem(
                  value: globals.QuizOrder.random,
                  child: Text('shuffle'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: title_filenames.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: Color(0xFFFFE2E1)),
            child: ListTile(
              key: ValueKey(title_filenames[index]["filename"]),
              dense: true,
              minVerticalPadding: 28,
              contentPadding: EdgeInsets.symmetric(horizontal: 48),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title_filenames[index]["title"].toString(),
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    updatedAtTrans(
                      title_filenames[index]['updatedAt'].toString(),
                    ),
                    style: TextStyle(color: Colors.grey[900], fontSize: 12),
                  ),
                ],
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            FlashCard(title_filename: title_filenames[index]),
                  ),
                ).then((_) {
                  setState(() {}); // → globals.title_filenamesが更新された内容で再描画される
                });
              },
            ),
          );
        },
      ),
    );
  }
}
