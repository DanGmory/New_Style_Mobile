import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/image_service.dart';

/// Widget especializado para mostrar imágenes de productos con fallbacks automáticos
class ProductImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingIndicator;
  
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = true,
  });

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  late List<String> _imageUrls;
  int _currentUrlIndex = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = ImageService.getAlternativeImageUrls(widget.imageUrl);
    _loadImage();
  }

  @override
  void didUpdateWidget(ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageUrls = ImageService.getAlternativeImageUrls(widget.imageUrl);
      _currentUrlIndex = 0;
      _hasError = false;
      _loadImage();
    }
  }

  void _loadImage() {
    if (_currentUrlIndex >= _imageUrls.length) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
    });
  }

  void _tryNextUrl() {
    // En web, los errores de CORS son definitivos (no podemos trabajarlos alrededor)
    // por lo que marcamos como error después del primer intento
    if (kIsWeb && _currentUrlIndex > 0) {
      setState(() {
        _hasError = true;
      });
      return;
    }
    
    if (_currentUrlIndex < _imageUrls.length - 1) {
      setState(() {
        _currentUrlIndex++;
        _loadImage();
      });
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  Widget _buildImage() {
    if (_currentUrlIndex >= _imageUrls.length) {
      return _buildErrorWidget();
    }

    return Image.network(
      _imageUrls[_currentUrlIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        
        if (widget.showLoadingIndicator) {
          return _buildLoadingWidget(loadingProgress);
        }
        
        return widget.placeholder ?? _buildDefaultPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Error cargando imagen ${_imageUrls[_currentUrlIndex]}: $error');
        
        // Intentar con la siguiente URL
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryNextUrl();
        });
        
        // Mostrar placeholder mientras se intenta la siguiente URL
        return widget.placeholder ?? _buildDefaultPlaceholder();
      },
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
        : null;

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: widget.height != null && widget.height! > 100 ? 40 : 24,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              'Cargando imagen...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: widget.height != null && widget.height! > 100 ? 40 : 24,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              'Imagen no disponible',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget image = _hasError ? _buildErrorWidget() : _buildImage();

    if (widget.borderRadius != null) {
      image = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Widget optimizado específicamente para tarjetas de producto
class ProductCardImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  const ProductCardImage({
    super.key,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = ProductImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
      ),
    );

    if (onTap != null) {
      image = GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    return image;
  }
}

/// Widget optimizado para vista de detalles de producto
class ProductDetailImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  const ProductDetailImage({
    super.key,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ProductImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(16),
      ),
    );

    if (onTap != null) {
      image = GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    return image;
  }
}