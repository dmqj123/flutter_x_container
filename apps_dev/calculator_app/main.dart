import 'dart:math' as math;

/// CalculatorState manages the calculator's internal state and operations
class CalculatorState {
  String _displayValue = '0';
  double? _firstOperand;
  String? _pendingOperator;
  bool _waitingForOperand = false;

  String get displayValue => _displayValue;

  /// Handles input of a number
  void inputDigit(String digit) {
    if (_waitingForOperand) {
      _displayValue = digit;
      _waitingForOperand = false;
    } else {
      _displayValue = _displayValue == '0' ? digit : _displayValue + digit;
    }
  }

  /// Handles decimal point input
  void inputDecimal() {
    if (_waitingForOperand) {
      _displayValue = '0.';
      _waitingForOperand = false;
    } else if (!_displayValue.contains('.')) {
      _displayValue = _displayValue + '.';
    }
  }

  /// Handles input of an operator
  void inputOperator(String op) {
    if (_firstOperand == null) {
      _firstOperand = double.tryParse(_displayValue);
    } else if (!_waitingForOperand) {
      String result = performCalculation();
      _firstOperand = double.tryParse(result);
    }
    
    _pendingOperator = op;
    _waitingForOperand = true;
  }

  /// Performs the calculation based on the current operator
  String performCalculation() {
    if (_firstOperand == null || _pendingOperator == null) {
      return _displayValue;
    }

    double inputValue = double.tryParse(_displayValue) ?? 0.0;
    double result = 0.0;

    switch (_pendingOperator) {
      case '+':
        result = _firstOperand! + inputValue;
        break;
      case '-':
        result = _firstOperand! - inputValue;
        break;
      case '*':
        result = _firstOperand! * inputValue;
        break;
      case '/':
        if (inputValue == 0) {
          return 'Error';
        }
        result = _firstOperand! / inputValue;
        break;
      default:
        result = inputValue;
    }

    // Format the result to remove unnecessary decimal places
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toString();
    }
  }

  /// Calculates the final result when equals is pressed
  void calculateResult() {
    if (_firstOperand != null && _pendingOperator != null) {
      _displayValue = performCalculation();
      _firstOperand = null;
      _pendingOperator = null;
      _waitingForOperand = true;
    }
  }

  /// Clears all calculator data
  void clearAll() {
    _displayValue = '0';
    _firstOperand = null;
    _pendingOperator = null;
    _waitingForOperand = false;
  }

  /// Handles special functions like percentage
  void inputPercentage() {
    double currentValue = double.tryParse(_displayValue) ?? 0.0;
    _displayValue = (currentValue / 100).toString();
  }

  /// Handles sign change (+/-)
  void toggleSign() {
    double currentValue = double.tryParse(_displayValue) ?? 0.0;
    currentValue = -currentValue;
    
    if (currentValue == currentValue.toInt()) {
      _displayValue = currentValue.toInt().toString();
    } else {
      _displayValue = currentValue.toString();
    }
  }
}

// Global calculator instance
final CalculatorState _calculator = CalculatorState();

/// Handles when a number button is pressed
void numberPressed_0() {
  _calculator.inputDigit('0');
  updateDisplay();
}

void numberPressed_1() {
  _calculator.inputDigit('1');
  updateDisplay();
}

void numberPressed_2() {
  _calculator.inputDigit('2');
  updateDisplay();
}

void numberPressed_3() {
  _calculator.inputDigit('3');
  updateDisplay();
}

void numberPressed_4() {
  _calculator.inputDigit('4');
  updateDisplay();
}

void numberPressed_5() {
  _calculator.inputDigit('5');
  updateDisplay();
}

void numberPressed_6() {
  _calculator.inputDigit('6');
  updateDisplay();
}

void numberPressed_7() {
  _calculator.inputDigit('7');
  updateDisplay();
}

void numberPressed_8() {
  _calculator.inputDigit('8');
  updateDisplay();
}

void numberPressed_9() {
  _calculator.inputDigit('9');
  updateDisplay();
}

/// Handles decimal point button press
void decimalPressed() {
  _calculator.inputDecimal();
  updateDisplay();
}

/// Handles operator button presses
void operatorPressed_add() {
  _calculator.inputOperator('+');
  updateDisplay();
}

void operatorPressed_subtract() {
  _calculator.inputOperator('-');
  updateDisplay();
}

void operatorPressed_multiply() {
  _calculator.inputOperator('*');
  updateDisplay();
}

void operatorPressed_divide() {
  _calculator.inputOperator('/');
  updateDisplay();
}

/// Handles equals button press
void equalsPressed() {
  _calculator.calculateResult();
  updateDisplay();
}

/// Updates the display with the current value
void updateDisplay() {
  // This function would update the display widget in the XML
  // The actual updating happens in the FlutterX Container framework
  print('Display updated to: ${_calculator.displayValue}');
}

/// Gets the current display value for the XML interface
String getDisplayValue() {
  return _calculator.displayValue;
}

/// Handles clear button press
void clearAll() {
  _calculator.clearAll();
  updateDisplay();
}

/// Handles percentage button press
void inputPercentage() {
  _calculator.inputPercentage();
  updateDisplay();
}

/// Handles sign toggle button press
void toggleSign() {
  _calculator.toggleSign();
  updateDisplay();
}