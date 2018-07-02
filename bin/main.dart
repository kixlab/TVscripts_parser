import 'dart:convert';

import 'package:scripts_parser/scripts_parser.dart' as scripts_parser;
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';


class Dialog {
  String context = "";
  List<Line> lines = [];

  Map toMap(){
    return {
      "context": context,
      "lines": lines.map((e) => e.toMap()).toList()
    };
  }
}

class Line {
  String speaker;
  String message;
  Line(this.speaker, this.message);

  Map toMap(){
    return {
      "speaker": speaker,
      "message": message
    };
  }
}


Future<List<FileSystemEntity>> dirContents(Directory dir) {
  var files = <FileSystemEntity>[];
  var completer = new Completer<List<FileSystemEntity>>();
  var lister = dir.list(recursive: false);
  lister.listen ( 
      (file) => files.add(file),
      // should also register onError
      onDone:   () => completer.complete(files)
      );
  return completer.future;
}

List<Dialog> parseHtml(String filePath) {
  var string = new File(filePath).readAsStringSync();
  var document = parse(string);
  List<Dialog> dialogs = [];
  var tables = document.querySelectorAll("table[width='100%']");
  for (var table in tables){
    var dialog = new Dialog();
    var trs = table.querySelectorAll("tr");
    for (var tr in trs){
      var left = tr.querySelector("td[id=left]");
      var right = tr.querySelector("td[id=right]");
      if (left == null || right == null) continue;
      dialog.lines.add(new Line(left.text.trim(), right.text.trim()));
      print("left:  "+left.text.trim());
      print("right: " +right.text.trim());
    }
    if (dialog.lines.length > 0){
      dialogs.add(dialog);
      print("======");
    }
  }
  return dialogs;
}



main(List<String> arguments) async {
  var files = await dirContents(new Directory("scripts"));
  for (var f in files){
    var dialogs = parseHtml(f.path);
    var payload = json.encode(dialogs.map((e) => e.toMap()).toList());
    new File(f.path +".json").writeAsStringSync(payload);
  }
}
