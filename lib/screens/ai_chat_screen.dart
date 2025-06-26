import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:productos_app/screens/home_screen.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class Producto {
  final String itemCode;
  final String itemName;
  final int stockMed;
  final int stockCart;
  final int stockCali;
  final int stockBog;
  final int stockFull;
  final String? urlPicture;
  final double? price;
  final bool? hasImageError;

  Producto(
      {required this.itemCode,
      required this.itemName,
      required this.stockMed,
      required this.stockCart,
      required this.stockCali,
      required this.stockBog,
      required this.stockFull,
      this.urlPicture,
      this.price,
      this.hasImageError});

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      stockMed: json['stockMed'] ?? '',
      stockCart: json['stockCart'] ?? '',
      stockCali: json['stockCali'] ?? '',
      stockBog: json['stockBog'] ?? '',
      stockFull: json['stockFull'] ?? 0,
      urlPicture: json['urlPicture'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      hasImageError: true,
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
  String empresa = GetStorage().read('empresa');
  String codigoAsesor = GetStorage().read('slpCode');
  final numberFormat = new NumberFormat.simpleCurrency();
  List<String> greets = [
    "hola",
    "hey",
    "ey",
    "que tal",
    "qué tal",
    "buenas",
    "holi",
    "oli",
    "ey",
    "quiubo",
    "como vas",
    "cómo vas",
    "saludos",
    "buenos días",
    "buenos dias",
    "buenas tardes",
    "buenas noches",
    "ayuda"
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();

    // Cargar el historial del chat
    final savedChat = storage.read('chat_history');
    if (savedChat != null) {
      chatHistory = List<Map<String, dynamic>>.from(
        (savedChat as List).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    }

    // Saludar al asesor al ingresar
    if (nombreAsesor == null) {
      nombreAsesor = "Asesor";
    } else {
      List<String> partes = nombreAsesor.toString().split(" ");
      print(partes.length);
      if (partes.length > 2) {
        String primerNombre = partes.first;
        String primerApellido = partes[partes.length - 2];
        nombreAsesor = "$primerNombre $primerApellido";
      }
    }

    setState(() {
      chatHistory.add({
        'assistant':
            'Hola $nombreAsesor, soy la inteligencia artificial entrenada para $empresa, y estoy aquí para brindarte una mejor atención y experiencia. Ey! ten en cuenta que solo doy información de productos con inventario.\nPor favor, indícame claramente en qué puedo ayudarte.'
      });
    });

    // Esperar hasta que el frame actual esté completamente renderizado
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _scrollToBottomWithRetry();
      },
    );
  }

  void _scrollToBottomWithRetry({int retries = 5}) async {
    if (!_scrollController.hasClients) return;

    await Future.delayed(const Duration(milliseconds: 100));

    double previousOffset = -1;
    int attempts = 0;

    while (attempts < retries) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (!_scrollController.hasClients) break;

      double maxScroll = _scrollController.position.maxScrollExtent;

      if (previousOffset == maxScroll) break;

      _scrollController.jumpTo(maxScroll);

      previousOffset = maxScroll;
      attempts++;
    }
  }

  void _initializeSpeech() async {
    try {
      // Solicitar permiso de micrófono
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done') {
              setState(
                () {
                  _isListening = false;
                },
              );
            }
          },
        );
        if (available) {
          setState(() {
            _speechEnabled = true;
          });
        }
      }
    } catch (e) {}
  }

  void _startListening() async {
    if (!_speechEnabled) {
      //print('Reconocimiento de voz no está habilitado');
      return;
    }

    try {
      if (!_isListening) {
        bool available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (result) {
              setState(
                () {
                  _controller.text = result.recognizedWords;
                },
              );
            },
            localeId: 'es-ES',
          );
        }
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } catch (e) {}
  }

  void _scrollToBottom() {
    Future.delayed(
      Duration(milliseconds: 100),
      () {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
              //_scrollController.animateTo(
              //_scrollController.position.maxScrollExtent + 10000000,
              //duration: const Duration(milliseconds: 300),
              //curve: Curves.easeOut,
              //);
            }
          },
        );
      },
    );
  }

  Future<void> greetUser(String message) async {}

  Future<void> sendMessage(String message) async {
    setState(() {
      isLoading = true;
      chatHistory.add({'user': message});
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://wali.igbcolombia.com:8080/manager/res/chatbot/interpret-input-text'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json; charset=utf-8'
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': message,
            'rol': 'user',
            'slpCode': codigoAsesor,
            'slpName': nombreAsesor,
            'companyName': empresa
          },
        ),
      );

      Map<String, dynamic> resp = jsonDecode(response.body);
      final dataList = resp["content"];

      if (resp["code"] == 0) {
        for (var data in dataList) {
          chatHistory.add(
            {
              'product': {
                'code': data['articulo'],
                'name': data['description'],
                'stockMed': data['stockMedellin'],
                'stockCart': data['stockCartagena'],
                'stockCali': data['stockCali'],
                'stockBog': data['stockBogota'],
                'stockFull': data['stockMedellin'] +
                    data['stockCartagena'] +
                    data['stockCali'] +
                    data['stockBogota'],
                'image': 'http://wali.igbcolombia.com:8080/shared/images/mtz/' +
                    data['foto'],
                'price': data['precio'],
              }
            },
          );
        }
      } else {
        setState(() {
          chatHistory.add({'assistant': resp["content"]});
        });
      }
      // Guardar el chat actualizado
      storage.write('chat_history', chatHistory);
      // Scroll al último mensaje
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          _scrollToBottom();
        },
      );
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        chatHistory.add({
          'assistant':
              'Uy, no puede ser $nombreAsesor, hubo una situación con tu conexión. Échale un vistazo a tu wifi o datos y vuelve a intentarlo más tarde.'
        });
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    /*if (response.statusCode == 200) {
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
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        setState(() {
                          chatHistory.clear();
                          storage.remove('chat_history');
                          isLoading = false;
                        });
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
                    message['product'] as Map<String, dynamic>,
                  );
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
                      hintText: 'Pregúntame...',
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
                  icon: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  ),
                  onPressed: _startListening,
                  color: _isListening ? Colors.red : null,
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded),
                  onPressed: () {
                    _isListening = false;
                    if (_controller.text.isNotEmpty) {
                      var aux = false;
                      for (var greet in greets) {
                        if (_controller.text
                            .toLowerCase()
                            .contains(greet.toLowerCase())) {
                          aux = true;
                          break;
                        }
                      }
                      if (aux) {
                        setState(() {
                          isLoading = true;
                          chatHistory.add({'user': _controller.text});
                        });
                        setState(() {
                          chatHistory.add({
                            'assistant':
                                'Hola $nombreAsesor, ¿En qué puedo ayudarte hoy? ¡Estoy aquí para lo que necesites!'
                          });
                        });
                        setState(() {
                          isLoading = false;
                        });
                      } else {
                        sendMessage(_controller.text);
                      }
                      _controller.clear();
                    }
                    // Scroll al último mensaje
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) {
                        _scrollToBottom();
                      },
                    );
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
                      .map(
                        (url) => ClipRRect(
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
                        ),
                      )
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
    String precioTxt = numberFormat.format(product['price']);
    bool promo = false;

    if (precioTxt.contains('.')) {
      int decimalIndex = precioTxt.indexOf('.');
      precioTxt = precioTxt.substring(0, decimalIndex);
    }

    if (product['name'].contains("*") ||
        product['name'].contains("**") ||
        product['name'].contains("COMBO")) {
      promo = true;
    } else {
      promo = false;
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
            if (product['image'] != null &&
                product['image'].toString().isNotEmpty)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 200,
                  height: 200,
                  margin: EdgeInsets.only(bottom: 8),
                  child: Image.network(
                    product['image'].toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          product['hasImageError'] = false;
                        });
                      });
                      return const Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
            Center(
              child: Text(
                product['code'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              product['name'],
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.justify,
            ),
            SizedBox(
              height: 5,
            ),
            if (product['stockMed'] != 0)
              Text(
                "Medellín: " + product['stockMed'].toString() + " disponibles",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            if (product['stockCart'] != 0)
              Text(
                "Cartagena: " +
                    product['stockCart'].toString() +
                    " disponibles",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            if (product['stockCali'] != 0)
              Text(
                "Cali: " + product['stockCali'].toString() + " disponibles",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            if (product['stockBog'] != 0)
              Text(
                "Bogotá: " + product['stockBog'].toString() + " disponibles",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            SizedBox(
              height: 5,
            ),
            if (product['price'] != null)
              Text(
                precioTxt,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            SizedBox(
              height: 5,
            ),
            if (promo)
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(
                      text:
                          "hay promoción limitada de este producto para este mes, con ",
                    ),
                    TextSpan(
                      text: product['stockFull'].toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          " unidades en stock disponible. Aprovecha la oferta y comercialízalo con tus clientes. ¡Corre a montar pedido, " +
                              nombreAsesor.toString() +
                              ", que es hasta agotar existencias!",
                    ),
                  ],
                ),
              ),
            if (!promo)
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: "Oye, tenemos disponible "),
                    TextSpan(
                      text: product['stockFull'].toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (product['stockFull'] == 1)
                      TextSpan(
                        text:
                            " unidad en stock para vender en este momento. \nTen en cuenta que en ",
                      ),
                    if (product['stockFull'] > 1)
                      TextSpan(
                        text:
                            " unidades en stock para vender en este momento. \nTen en cuenta que en ",
                      ),
                    TextSpan(
                      text: empresa,
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                    TextSpan(
                      text:
                          " el inventario varia todo el tiempo, así que lo que estás viendo puede no estar mañana.",
                    ),
                  ],
                ),
              ),
            if (product['hasImageError'] == false)
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(
                      text:
                          "\nDiscúlpame por no haberte mostrado la foto, sé lo importante que es; lo que pasa es que no la encontré. Lo más seguro es que Mercadeo esté trabajando en ello.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
