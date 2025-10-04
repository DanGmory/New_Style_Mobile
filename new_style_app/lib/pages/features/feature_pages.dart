import 'package:flutter/material.dart';
import '../../widgets/under_development.dart';

// Página de Favoritos
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderDevelopmentPage(
      featureName: 'Favoritos',
      icon: Icons.favorite_outlined,
      description: 'Guarda y gestiona tus productos favoritos para encontrarlos fácilmente.',
      features: [
        'Lista de productos favoritos',
        'Filtros y búsqueda avanzada',
        'Notificaciones de precio',
        'Compartir favoritos',
        'Sincronización en la nube',
      ],
    );
  }
}

// Página de Lista de Deseos
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderDevelopmentPage(
      featureName: 'Lista de Deseos',
      icon: Icons.bookmark_outlined,
      description: 'Crea listas personalizadas de productos que deseas comprar en el futuro.',
      features: [
        'Múltiples listas temáticas',
        'Recordatorios de disponibilidad',
        'Comparación de precios',
        'Compartir listas con amigos',
        'Sugerencias inteligentes',
      ],
    );
  }
}

// Página de Reseñas
class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderDevelopmentPage(
      featureName: 'Mis Reseñas',
      icon: Icons.rate_review_outlined,
      description: 'Escribe y gestiona tus opiniones sobre los productos que has comprado.',
      features: [
        'Calificación con estrellas',
        'Fotos en reseñas',
        'Historial de reseñas',
        'Respuestas del vendedor',
        'Reseñas verificadas',
      ],
    );
  }
}

// Página de Ofertas
class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderDevelopmentPage(
      featureName: 'Ofertas Especiales',
      icon: Icons.local_offer_outlined,
      description: 'Descubre las mejores ofertas, descuentos y promociones exclusivas.',
      features: [
        'Ofertas diarias',
        'Descuentos por tiempo limitado',
        'Cupones personalizados',
        'Alertas de ofertas',
        'Programa de fidelidad',
      ],
    );
  }
}

// Página de Soporte
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderDevelopmentPage(
      featureName: 'Soporte al Cliente',
      icon: Icons.support_agent_outlined,
      description: 'Obtén ayuda personalizada y resuelve tus dudas con nuestro equipo de soporte.',
      features: [
        'Chat en vivo 24/7',
        'Centro de ayuda',
        'Preguntas frecuentes',
        'Tickets de soporte',
        'Videollamadas de asistencia',
      ],
    );
  }
}

// Página de Notificaciones
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnderDevelopmentPage(
      featureName: 'Centro de Notificaciones',
      icon: Icons.notifications_outlined,
      description: 'Gestiona todas tus notificaciones y mantente al día con las novedades.',
      features: [
        'Notificaciones push',
        'Historial completo',
        'Configuración personalizada',
        'Categorías de notificaciones',
        'Modo no molestar',
      ],
    );
  }
}
