# dreameats

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Customer Features Status

The following customer capabilities are implemented:

- [x] **Create account**: Supported via email, Google, Apple, and Phone.
- [x] **Login**: Secure authentication via Supabase.
- [x] **Browse available food deals**: Real-time feed of surplus packages.
- [x] **Search businesses**: Full-text search for restaurants and bakeries.
- [x] **Filter by**:
    - [x] Distance (Geolocation-based)
    - [x] Price ranges
    - [x] Food type (Categories)
    - [x] Pickup time windows
- [x] **Reserve food packages**: Claim surplus items for pickup.
- [x] **Pay through Mobile Money**: Integrated via Paystack (MTN, AirtelTigo, Telecel).
- [x] **Save favorite businesses**: Quick access to preferred merchants.
- [x] **View order history**: Dashboard for active and past reservations.
- [x] **Rate purchases**: Star ratings and reviews for collected orders.
- [x] **Receive notifications**: Push notification support for order updates.

---

### 🔐 Administrative Access

The project features a multi-tiered management system isolated by port for security:

*   **Customer/Merchant Site**: `http://localhost:8080`
*   **Staff Admin Portal**: `http://localhost:8081`

#### How to create a Super Admin:
1.  Sign up a user through the main app or Supabase Auth.
2.  Go to your Supabase Dashboard → SQL Editor.
3.  Run the following query to elevate the user:
    ```sql
    UPDATE profiles 
    SET role = 'super_admin' 
    WHERE email = 'your-admin-email@example.com';
    ```
4.  Log in at `http://localhost:8081` using the **Super Admin** toggle.
