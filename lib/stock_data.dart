// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Snapshot from http://www.nasdaq.com/screening/company-list.aspx
// Fetched 2/23/2014.
// "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
// Data in stock_data.json

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

final math.Random _rng = math.Random();

class Stock {
  Stock(this.symbol, this.name, this.lastSale, this.marketCap, this.percentChange);

  Stock.fromFields(List<String> fields) {
    // FIXME: This class should only have static data, not lastSale, etc.
    // "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
    lastSale = 0.0;
    try {
      lastSale = double.parse(fields[2]);
    } catch (_) { }
    symbol = fields[0];
    name = fields[1];
    marketCap = fields[4];
    percentChange = (_rng.nextDouble() * 20) - 10;
  }

  String symbol;
  String name;
  double lastSale;
  String marketCap;
  double percentChange;
}

class StockData extends ChangeNotifier {
  StockData() {
    if (actuallyFetchData) {
      _httpClient = http.Client();
      _fetchNextChunk();
    }
  }

  final List<String> _symbols = <String>[];
  final Map<String, Stock> _stocks = <String, Stock>{};

  Iterable<String> get allSymbols => _symbols;

  Stock operator [](String symbol) => _stocks[symbol];

  bool get loading => _httpClient != null;

  void add(List<dynamic> data) {
    for (List<dynamic> fields in data) {
      final Stock stock = Stock.fromFields(fields.cast<String>());
      _symbols.add(stock.symbol);
      _stocks[stock.symbol] = stock;
    }
    _symbols.sort();
    notifyListeners();
  }

  static const int _chunkCount = 30;
  int _nextChunk = 0;

  String _urlToFetch(int chunk) {
    return 'https://domokit.github.io/examples/stocks/data/stock_data_$chunk.json';
  }

  http.Client _httpClient;

  static bool actuallyFetchData = true;

  void _fetchNextChunk() {
    _httpClient.get(Uri.parse(_urlToFetch(_nextChunk++))).then<void>((http.Response response) {
      final String json = response.body;
      if (json == null) {
        debugPrint('Failed to load stock data chunk ${_nextChunk - 1}');
        _end();
        return;
      }
      const JsonDecoder decoder = JsonDecoder();
      add(decoder.convert(json));
      if (_nextChunk < _chunkCount) {
        _fetchNextChunk();
      } else {
        _end();
      }
    });
  }

  void _end() {
    _httpClient?.close();
    _httpClient = null;
  }
}
