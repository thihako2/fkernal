/// Interface for models that support validation and serialization.
///
/// Implement this interface to allow [ApiClient] to automatically:
/// 1. Validate the model before sending the request.
/// 2. Serialize the model to JSON.
abstract class FKernalModel {
  /// Serializes the model to a JSON map.
  Map<String, dynamic> toJson();

  /// Validates the model's data.
  ///
  /// Should throw [FKernalError.validation] if the data is invalid.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void validate() {
  ///   if (email.isEmpty) {
  ///     throw FKernalError.validation(message: 'Email is required');
  ///   }
  /// }
  /// ```
  void validate();
}
