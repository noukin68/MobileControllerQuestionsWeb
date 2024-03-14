import 'package:flutter/material.dart';
import 'package:flutter_application_1/timer_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final IO.Socket socket;

  LoginPage(this.socket);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late IO.Socket socket;
  TextEditingController uidController = TextEditingController();
  List<String> connectedUIDs = [];
  Map<String, IO.Socket> sockets = {};

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    socket = IO.io('http://62.217.182.138:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    // Обработка сообщения об ошибке
    socket.on('error', (errorMessage) {
      showErrorMessage(errorMessage);
    });
  }

  Future<void> saveConnectedUIDs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('connectedUIDs', connectedUIDs);
  }

  void addUID(String uid) {
    setState(() {
      if (!connectedUIDs.contains(uid)) {
        connectedUIDs.add(uid);
        IO.Socket newSocket =
            IO.io('http://62.217.182.138:3000', <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        });
        newSocket.connect();
        // Отправляем запрос на сервер для присоединения к комнате с соответствующим uid
        newSocket.emit('join', uid);
        sockets[uid] =
            newSocket; // Сохраняем новый экземпляр сокета для данного UID
      }
    });
  }

  void removeUID(String uid) {
    setState(() {
      connectedUIDs.remove(uid);
    });
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ошибка'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void checkUIDExists(String uid) {
    socket.emit('check_uid', uid);
    socket.once('uid_check_result', (data) {
      bool exists = data['exists'];
      if (exists) {
        addUID(uid);
      } else {
        showErrorMessage('UID не существует');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFCEAD),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 20),
            Text(
              'Родительский контроль',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(119, 75, 36, 1),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: uidController,
              style: TextStyle(
                color: Color.fromRGBO(119, 75, 36, 1),
              ),
              decoration: InputDecoration(
                hintText: 'Введите UID',
                hintStyle: TextStyle(
                  color: Color.fromRGBO(119, 75, 36, 1),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(119, 75, 36, 1),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String uid = uidController.text.trim();
                if (uid.isNotEmpty) {
                  // Проверяем, что uid не пустой
                  addUID(uid);
                  uidController.clear(); // Здесь отправляется команда на сервер
                } else {
                  showErrorMessage('Пожалуйста, введите действительный UID');
                }
              },
              child: Text('Добавить соединение'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Color.fromRGBO(239, 206, 173, 1),
                backgroundColor: Color.fromRGBO(119, 75, 36, 1),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: connectedUIDs.isEmpty
                  ? Center(
                      child: Text('У пользователя нет подключений'),
                    )
                  : ListView.builder(
                      itemCount: connectedUIDs.length,
                      itemBuilder: (context, index) {
                        String uid = connectedUIDs[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 4,
                          color: Color.fromRGBO(239, 206, 173, 1),
                          child: ListTile(
                            title: Text(
                              uid,
                              style: TextStyle(
                                color: Color.fromRGBO(119, 75, 36, 1),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  color: Color.fromRGBO(119, 75, 36, 1),
                                  onPressed: () {
                                    removeUID(uid);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.arrow_forward),
                                  color: Color.fromRGBO(119, 75, 36, 1),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TimerScreen(
                                          socket: sockets[
                                              uid]!, // Используйте соответствующий экземпляр сокета для данного UID
                                          uid: uid,
                                        ),
                                      ),
                                    ).then((_) {
                                      // При возврате из TimerScreen ничего не делаем
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),
            Text(
              'при поддержке',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(119, 75, 36, 1),
                fontFamily: 'Calibri',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/pixel.png',
                  width: 90,
                  height: 90,
                ),
                SizedBox(
                  width: 10,
                ),
                Image.asset(
                  'assets/faz.png',
                  width: 90,
                  height: 90,
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
