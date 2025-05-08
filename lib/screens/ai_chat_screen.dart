import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:productos_app/screens/home_screen.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Producto {
  final String itemCode;
  final String itemName;
  final int stockFull;
  final String? urlPicture;
  final double? price;

  Producto({
    required this.itemCode,
    required this.itemName,
    required this.stockFull,
    this.urlPicture,
    this.price,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      stockFull: json['stockFull'] ?? 0,
      urlPicture: json['urlPicture'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
    );
  }
}

class AIChatScreen extends StatefulWidget {
  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final GetStorage storage = GetStorage();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> chatHistory = [];
  bool isLoading = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  String? nombreAsesor = GetStorage().read('nombreAsesor');

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    // Cargar el historial del chat
    final savedChat = storage.read('chat_history');
    if (savedChat != null) {
      chatHistory = List<Map<String, dynamic>>.from(
          (savedChat as List).map((item) => Map<String, dynamic>.from(item)));
    }
    // Agregar un pequeño delay para permitir que el ListView se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _initializeSpeech() async {
    try {
      // Solicitar permiso de micrófono
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (status) {
            print('Estado del reconocimiento de voz: $status');
            if (status == 'done') {
              setState(() {
                _isListening = false;
              });
            }
          },
          onError: (error) => print('Error en reconocimiento de voz: $error'),
        );
        if (available) {
          setState(() {
            _speechEnabled = true;
          });
          print('Reconocimiento de voz inicializado correctamente');
        } else {
          print('Reconocimiento de voz no disponible');
        }
      } else {
        print('Permiso de micrófono denegado');
      }
    } catch (e) {
      print('Error al inicializar el reconocimiento de voz: $e');
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      print('Reconocimiento de voz no está habilitado');
      return;
    }

    try {
      if (!_isListening) {
        bool available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (result) {
              print('Texto reconocido: ${result.recognizedWords}');
              setState(() {
                _controller.text = result.recognizedWords;
              });
            },
            localeId: 'es-ES', // Configurar para español
          );
        } else {
          print('No se pudo iniciar el reconocimiento de voz');
        }
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } catch (e) {
      print('Error al iniciar/detener el reconocimiento de voz: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      isLoading = true;
      chatHistory.add({'user': message});
    });

    if (nombreAsesor == null) nombreAsesor = "Asesor";
    try {
      final response = await http.post(
        Uri.parse('http://20.206.250.57:5002/consultar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json; charset=utf-8',
        },
        body: json.encode({'pregunta': message, 'usuario': '$nombreAsesor'}),
      );

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        print('Respuesta del servidor: $decodedBody'); // Para depuración

        try {
          // Intentar decodificar como JSON
          final Map<String, dynamic> jsonResponse = json.decode(decodedBody);

          if (jsonResponse.containsKey('respuesta')) {
            // Si la respuesta es un string simple
            if (jsonResponse['respuesta'] is String) {
              chatHistory.add({'assistant': jsonResponse['respuesta']});
            }
            // Si la respuesta es un objeto JSON
            else if (jsonResponse['respuesta'] is Map) {
              final Map<String, dynamic> respuesta = jsonResponse['respuesta'];

              // Agregar mensaje con el resultado de la agregación si existe
              if (respuesta.containsKey('resultado') &&
                  respuesta['resultado'] != null &&
                  !respuesta.containsKey('productos')) {
                chatHistory.add({'assistant': '${respuesta['resultado']}'});
              }

              // Agregar mensaje con la cantidad de productos si existe
              if (respuesta.containsKey('cantidad_productos')) {
                chatHistory.add({
                  'assistant':
                      'Se encontraron ${respuesta['cantidad_productos']} productos:'
                });
              }

              // Procesar los productos si existen
              if (respuesta.containsKey('productos') &&
                  respuesta['productos'] is List) {
                final List<dynamic> productosList = respuesta['productos'];
                for (var producto in productosList) {
                  chatHistory.add({
                    'product': {
                      'code': producto['itemCode'],
                      'name': producto['itemName'],
                      'stock': producto['stockFull'],
                      'image': producto['urlPicture'],
                      'price': producto['price'],
                    }
                  });
                }
              }
            }
          } else {
            setState(() {
              chatHistory.add(
                  {'assistant': 'No se pudo obtener una respuesta válida.'});
            });
          }
        } catch (e) {
          print('Error al procesar la respuesta JSON: $e');
          // Si falla el parseo JSON, intentar mostrar la respuesta como texto plano
          setState(() {
            chatHistory.add({'assistant': decodedBody});
          });
        }

        // Guardar el chat actualizado
        storage.write('chat_history', chatHistory);
        // Scroll al último mensaje
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        print('Error en la respuesta: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
        setState(() {
          chatHistory.add({
            'assistant':
                'Error en la respuesta del servidor. Por favor, intenta de nuevo.'
          });
        });
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      setState(() {
        chatHistory.add({
          'assistant':
              'Error de conexión. Por favor, verifica tu conexión a internet.'
        });
      });
    } finally {
      setState(
        () {
          isLoading = false;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onTap: () {
            storage.remove('observaciones');
            storage.remove("pedido");
            storage.remove("itemsPedido");
            storage.remove("dirEnvio");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          },
        ),
        title: Text(
          'Chatbot',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromRGBO(30, 129, 235, 1),
        actions: [
          // Agregar botón para limpiar historial
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Limpiar historial'),
                  content: Text(
                    '¿Estás seguro de que deseas borrar todo el historial del chat?',
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancelar'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text('Aceptar'),
                      onPressed: () {
                        setState(
                          () {
                            chatHistory.clear();
                            storage.remove('chat_history');
                          },
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final message = chatHistory[index];
                if (message.containsKey('user')) {
                  return _buildUserMessage(message['user'] as String);
                } else if (message.containsKey('assistant')) {
                  return _buildAssistantMessage(message['assistant'] as String);
                } else if (message.containsKey('product')) {
                  return _buildProductCard(
                      message['product'] as Map<String, dynamic>);
                }
                return SizedBox.shrink();
              },
            ),
          ),
          if (isLoading) LinearProgressIndicator(),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        sendMessage(text);
                        _controller.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening
                      ? Icons.mic_rounded
                      : Icons.mic_none_rounded),
                  onPressed: _startListening,
                  color: _isListening ? Colors.red : null,
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color.fromRGBO(30, 129, 235, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(String message) {
    // Detectar todas las URLs de imágenes en el mensaje
    final imageUrls = _extractImageUrls(message);
    String textWithoutImages = message;

    // Remover todas las URLs de imágenes del texto
    for (var url in imageUrls) {
      textWithoutImages = textWithoutImages.replaceAll(url, '').trim();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (textWithoutImages.isNotEmpty) Text(textWithoutImages),
            if (imageUrls.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: imageUrls
                      .map((url) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _extractImageUrls(String message) {
    final RegExp urlRegex = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)\.(jpg|jpeg|png|gif|webp)',
      caseSensitive: false,
    );

    return urlRegex
        .allMatches(message)
        .map((match) => match.group(0)!)
        .toList();
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['image'] != null &&
                product['image'].toString().isNotEmpty)
              Container(
                width: 200,
                height: 200,
                margin: EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product['image'].toString(),
                    placeholder: (context, url) => Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('Error al cargar la imagen: $error');
                      print('URL de la imagen: $url');
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              'Error al cargar la imagen',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              'Código: ${product['code']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Nombre: ${product['name']}'),
            Text('Stock: ${product['stock']} unidades'),
            if (product['price'] != null)
              Text(
                'Precio: \$${product['price'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
