import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDatabase();
    return _db;
  }

  DatabaseHelper.internal();

  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "pedidos.db");

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pedido (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardCode TEXT,
        cardName TEXT,
        comments TEXT,
        companyName TEXT,
        numAtCard TEXT,
        shipToCode TEXT,
        payToCode TEXT,
        slpCode INTEGER,
        discountPercent REAL,
        docTotal REAL,
        lineNum TEXT,
        detailSalesOrder TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_pedido INTEGER,
        quantity INTEGER,
        itemCode TEXT,
        itemName TEXT,
        grupo TEXT,
        whsCode TEXT,
        presentation TEXT,
        price REAL,
        discountItem REAL,
        discountPorc REAL,
        iva REAL
      )
    ''');
  }

  // Métodos CRUD para la tabla "pedido"
  Future<int> insertPedido(Pedido pedido) async {
    final dbClient = await db;
    return await dbClient!.insert('pedido', pedido.toMap());
  }

  Future<List<Pedido>> getPedidos() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient!.query('pedido');

    return List.generate(maps.length, (index) {
      return Pedido(
        id: maps[index]['id'],
        cardCode: maps[index]['cardCode'],
        cardName: maps[index]['cardName'],
        comments: maps[index]['comments'],
        companyName: maps[index]['companyName'],
        numAtCard: maps[index]['numAtCard'],
        shipToCode: maps[index]['shipToCode'],
        payToCode: maps[index]['payToCode'],
        slpCode: maps[index]['slpCode'],
        discountPercent: maps[index]['discountPercent'],
        docTotal: maps[index]['docTotal'],
        lineNum: maps[index]['lineNum'],
        detailSalesOrder: maps[index]['detailSalesOrder'],
      );
    });
  }

  Future<int> updatePedido(Pedido pedido) async {
    final dbClient = await db;
    return await dbClient!.update('pedido', pedido.toMap(),
        where: 'id = ?', whereArgs: [pedido.id]);
  }

  Future<int> deletePedido(int id) async {
    final dbClient = await db;
    return await dbClient!.delete('pedido', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos CRUD para la tabla "items"
  Future<int> insertItem(Item item) async {
    final dbClient = await db;
    return await dbClient!.insert('items', item.toMap());
  }

  Future<List<Item>> getItems() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient!.query('items');

    return List.generate(maps.length, (index) {
      return Item(
        id: maps[index]['id'],
        idPedido: maps[index]['id_pedido'],
        quantity: maps[index]['quantity'],
        itemCode: maps[index]['itemCode'],
        itemName: maps[index]['itemName'],
        grupo: maps[index]['grupo'],
        whsCode: maps[index]['whsCode'],
        presentation: maps[index]['presentation'],
        price: maps[index]['price'],
        discountItem: maps[index]['discountItem'],
        discountPorc: maps[index]['discountPorc'],
        iva: maps[index]['iva'],
      );
    });
  }

  Future<int> updateItem(Item item) async {
    final dbClient = await db;
    return await dbClient!
        .update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final dbClient = await db;
    return await dbClient!.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllItemsP() async {
    final dbClient = await db;
    return await dbClient!.delete('pedido');
  }

  Future<int> deleteAllItems() async {
    final dbClient = await db;
    return await dbClient!.delete('items');
  }

  Future<int> getItemCount() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> articles = await dbClient!.query('items');
    return articles.length;
  }
}

// Métodos toMap y fromMap para convertir objetos a Map y viceversa
class Pedido {
  int? id;
  String? cardCode;
  String? cardName;
  String? comments;
  String? companyName;
  String? numAtCard;
  String? shipToCode;
  String? payToCode;
  int? slpCode;
  double? discountPercent;
  double? docTotal;
  String? lineNum;
  String? detailSalesOrder;

  Pedido({
    this.id,
    this.cardCode,
    this.cardName,
    this.comments,
    this.companyName,
    this.numAtCard,
    this.shipToCode,
    this.payToCode,
    this.slpCode,
    this.discountPercent,
    this.docTotal,
    this.lineNum,
    this.detailSalesOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardCode': cardCode,
      'cardName': cardName,
      'comments': comments,
      'companyName': companyName,
      'numAtCard': numAtCard,
      'shipToCode': shipToCode,
      'payToCode': payToCode,
      'slpCode': slpCode,
      'discountPercent': discountPercent,
      'docTotal': docTotal,
      'lineNum': lineNum,
      'detailSalesOrder': detailSalesOrder,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'],
      cardCode: map['cardCode'],
      cardName: map['cardName'],
      comments: map['comments'],
      companyName: map['companyName'],
      numAtCard: map['numAtCard'],
      shipToCode: map['shipToCode'],
      payToCode: map['payToCode'],
      slpCode: map['slpCode'],
      discountPercent: map['discountPercent'],
      docTotal: map['docTotal'],
      lineNum: map['lineNum'],
      detailSalesOrder: map['detailSalesOrder'],
    );
  }
}

class Item {
  int? id;
  int? idPedido;
  int? quantity;
  String? itemCode;
  String? itemName;
  String? grupo;
  String? whsCode;
  String? presentation;
  double? price;
  double? discountItem;
  double? discountPorc;
  double? iva;

  Item({
    this.id,
    this.idPedido,
    this.quantity,
    this.itemCode,
    this.itemName,
    this.grupo,
    this.whsCode,
    this.presentation,
    this.price,
    this.discountItem,
    this.discountPorc,
    this.iva,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_pedido': idPedido,
      'quantity': quantity,
      'itemCode': itemCode,
      'itemName': itemName,
      'grupo': grupo,
      'whsCode': whsCode,
      'presentation': presentation,
      'price': price,
      'discountItem': discountItem,
      'discountPorc': discountPorc,
      'iva': iva,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      idPedido: map['id_pedido'],
      quantity: map['quantity'],
      itemCode: map['itemCode'],
      itemName: map['itemName'],
      grupo: map['grupo'],
      whsCode: map['whsCode'],
      presentation: map['presentation'],
      price: map['price'],
      discountItem: map['discountItem'],
      discountPorc: map['discountPorc'],
      iva: map['iva'],
    );
  }
}
