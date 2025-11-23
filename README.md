# BazarLink Mobile App

A Flutter mobile application for the BazarLink platform, connecting suppliers and consumers (restaurants, hotels, etc.) for B2B food supply management.

## Overview

BazarLink Mobile is a comprehensive mobile application that enables:
- **Consumers** (restaurants, hotels, cafes) to browse supplier catalogs, place orders, manage links with suppliers, and communicate via chat
- **Sales Representatives** to manage orders, handle consumer relationships, respond to complaints, and communicate with consumers
- **Managers** to escalate and resolve complaints, oversee operations

## Features

### Consumer Features
- **Authentication**: Secure login and sign-up with password validation (minimum 6 characters with letters and numbers)
- **Supplier Management**: 
  - Browse all available suppliers
  - Request links with suppliers
  - View linked suppliers and their catalogs
  - Unlink from suppliers
- **Catalog & Products**:
  - Browse products by supplier
  - Filter products by category
  - View product details with pricing and availability
  - Add products to cart from product detail page
- **Shopping Cart**:
  - Manage cart items
  - Place orders with delivery method selection (delivery/pickup)
  - Specify delivery address and date
  - Add order notes
- **Order Management**:
  - View order history with status filtering
  - View detailed order information (items, delivery details, cancellation reasons)
  - Reorder previous orders (if still linked to supplier)
  - Restrictions for unlinked consumers (cannot reorder or view details)
- **Chat & Communication**:
  - Chat with linked suppliers
  - Send messages with attachments (images, files, receipts, products)
  - View complaint chats with escalation indicators
  - See manager messages with role badges
- **Complaints**:
  - Create complaints for orders
  - Track complaint status (open, escalated, resolved)
  - View escalation information

### Sales Representative Features
- **Consumer Management**:
  - View linked consumers
  - Filter by status (pending, accepted, removed, blocked)
  - Accept/reject link requests
  - Assign consumers to sales reps
  - Block consumers
- **Order Management**:
  - View all orders with status filtering
  - See order details including items, delivery information, and consumer notes
  - Accept/reject pending orders
  - Cancel orders with reason (visible to consumer)
  - Complete orders
  - View cancellation reasons
- **Chat**:
  - Communicate with assigned consumers
  - Send and receive messages
  - View message history
- **Complaints**:
  - View consumer complaints
  - Escalate complaints to managers
  - Track complaint status

## Technical Details

### Architecture
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Architecture Pattern**: Feature-based modular architecture
- **API Integration**: RESTful API client with repository pattern

### Project Structure
```
lib/
├── app.dart                    # Main app widget
├── main.dart                   # Entry point
├── core/                       # Core functionality
│   ├── localization/          # Internationalization
│   ├── network/              # API client
│   ├── routing/              # Navigation
│   └── widgets/              # Reusable widgets
├── features/                  # Feature modules
│   ├── auth/                 # Authentication
│   ├── consumer/             # Consumer features
│   │   ├── data/            # Data layer (API, mock)
│   │   ├── domain/          # Domain entities
│   │   └── presentation/    # UI pages
│   ├── sales/                # Sales rep features
│   └── settings/             # App settings
└── shell/                     # App shell/navigation
```

### Database Schema Alignment

The app aligns with the backend database schema:

#### Order Status Values
- `pending` - Order is pending approval
- `accepted` - Order accepted (treated as in_progress)
- `in_progress` - Order is being processed
- `completed` - Order completed
- `rejected` - Order rejected
- `cancelled` - Order cancelled (note: double 'l')

#### Link Status Values
- `pending` - Link request pending
- `accepted` - Link accepted
- `removed` - Link removed (consumer unlinked)
- `blocked` - Consumer blocked

#### Delivery Method
- `delivery` - Delivery to address
- `pickup` - Pickup from supplier

### Key Components

#### Authentication
- Login page with email/password
- Consumer sign-up with validation:
  - Password: minimum 6 characters with letters and numbers
  - Password confirmation field
  - Real-time validation feedback

#### Order Flow
1. Consumer adds products to cart
2. Selects delivery method (delivery/pickup)
3. Provides delivery details (address, date, notes)
4. Places order (status: `pending`)
5. Sales rep accepts/rejects order
6. Order moves to `in_progress` or `accepted`
7. Sales rep can cancel (with reason) or complete order
8. Order status: `completed`, `cancelled`, or `rejected`

#### Chat System
- Messages support text, images, files, receipts, and product links
- Escalation indicators for complaint chats
- Manager role badges for escalated messages
- Real-time message updates

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Backend API running and accessible

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd bazarlink-mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API endpoint:
   - Update API base URL in `lib/core/network/api_client.dart`
   - Or set via environment variables

4. Run the app:
```bash
flutter run
```

### Building

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Configuration

### API Configuration
The app uses a repository pattern with API and mock implementations:
- `ApiConsumerRepository` - Real API integration
- `MockConsumerRepository` - Mock data for testing
- `ApiSalesRepository` - Real API integration for sales
- `MockSalesRepository` - Mock data for testing

### Localization
The app supports multiple languages:
- English (en)
- Russian (ru)
- Kazakh (kk)

Localization files are in `lib/core/localization/`

## Status Handling

### Order Status
- **Pending**: Awaiting supplier approval
- **Accepted/In Progress**: Order being processed
- **Completed**: Order fulfilled
- **Rejected**: Order rejected by supplier
- **Cancelled**: Order cancelled (with reason stored in notes)

### Link Status
- **Pending**: Link request awaiting approval
- **Accepted**: Link active, consumer can order
- **Removed**: Consumer unlinked (cannot reorder or view details)
- **Blocked**: Consumer blocked by supplier

## Security Features

- Password validation on sign-up
- Secure authentication flow
- Role-based access control
- Link status validation for order operations

## Known Issues & Limitations

- Audio playback for voice messages not yet implemented
- File download functionality needs backend file serving
- Typing indicators for managers in escalated chats (to be implemented)

## Contributing

1. Follow Flutter/Dart style guidelines
2. Maintain feature-based architecture
3. Update this README for significant changes
4. Test on both Android and iOS before submitting

## License

[Add your license information here]

## Support

For issues and questions, please contact the development team or create an issue in the repository.
