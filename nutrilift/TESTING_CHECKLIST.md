# NutriLift Testing Checklist

## Backend Testing

### 1. API Endpoints Test
- [ ] **API Root:** Visit `http://127.0.0.1:8000/api/auth/` - Should show API documentation
- [ ] **Register Docs:** Visit `http://127.0.0.1:8000/api/auth/register/` - Should show registration docs
- [ ] **Login Docs:** Visit `http://127.0.0.1:8000/api/auth/login/` - Should show login docs
- [ ] **Profile Docs:** Visit `http://127.0.0.1:8000/api/auth/profile/` - Should show profile update docs

### 2. Authentication Flow Test
```bash
# Test registration (use Postman or curl)
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass123","name":"Test User"}'

# Test login
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass123"}'
```

## Frontend Testing

### 1. Navigation Test
- [ ] App launches successfully
- [ ] Bottom navigation shows 5 tabs: Home, Workout, Nutrition, Community, Gym Finder
- [ ] All tabs are clickable and switch screens
- [ ] **Gym Finder is positioned as the last tab (5th position)**

### 2. Gym Finder Functionality Test
- [ ] **Gym List Display:**
  - [ ] Shows list of gyms with cards
  - [ ] Each gym card shows: name, rating, distance, address, facilities
  - [ ] Open/Closed status is displayed correctly
  - [ ] Rating stars are visible

- [ ] **Search Functionality:**
  - [ ] Search bar is functional
  - [ ] Can search by gym name
  - [ ] Can search by facilities (e.g., "Pool", "Sauna")
  - [ ] Clear button works when text is entered

- [ ] **Filter Functionality:**
  - [ ] Filter chips are displayed: All, Near Me, Top Rated, New
  - [ ] Clicking filters changes the gym list order
  - [ ] Selected filter is highlighted

- [ ] **Gym Card Actions:**
  - [ ] "Call" button shows snackbar with phone number
  - [ ] "View Details" button navigates to gym details screen
  - [ ] Tapping anywhere on card also navigates to details

### 3. Gym Details Screen Test
- [ ] **Header Section:**
  - [ ] Gym image is displayed (or placeholder if image fails)
  - [ ] Gym name is shown in app bar
  - [ ] Favorite and share buttons are functional (show snackbars)

- [ ] **Quick Info Section:**
  - [ ] Rating badge is displayed
  - [ ] Distance is shown
  - [ ] Open/Closed status is correct
  - [ ] Address is displayed
  - [ ] "Call" and "Directions" buttons work (show snackbars)

- [ ] **Tab Navigation:**
  - [ ] Four tabs are visible: Overview, Photos, Pricing, Reviews
  - [ ] Tabs are clickable and switch content
  - [ ] Tab indicator follows selection

- [ ] **Overview Tab:**
  - [ ] "About" section shows gym description
  - [ ] "Facilities" shows facility chips
  - [ ] "Operating Hours" shows all days and times
  - [ ] "Amenities" shows checkmarked list

- [ ] **Photos Tab:**
  - [ ] Photos are displayed in a grid (2 columns)
  - [ ] Tapping photo opens image viewer dialog
  - [ ] Image viewer shows full-size image
  - [ ] Error handling for failed image loads

- [ ] **Pricing Tab:**
  - [ ] All membership plans are displayed as cards
  - [ ] Each plan shows: name, price, description, features
  - [ ] "Select Plan" buttons open booking dialog

- [ ] **Reviews Tab:**
  - [ ] Overall rating is displayed prominently
  - [ ] Star rating visualization works
  - [ ] Review count is shown
  - [ ] Individual reviews show: avatar, name, rating, date, comment

- [ ] **Booking Functionality:**
  - [ ] "Book Now" button at bottom opens booking dialog
  - [ ] Booking dialog shows gym name and selected plan (if any)
  - [ ] "Confirm Booking" shows success message
  - [ ] "Cancel" closes dialog without action

### 4. Authentication Integration Test
- [ ] **Registration:**
  - [ ] Can register new user through Flutter app
  - [ ] Success redirects to main navigation
  - [ ] Error messages are displayed properly

- [ ] **Login:**
  - [ ] Can login with registered credentials
  - [ ] Success redirects to main navigation
  - [ ] Invalid credentials show error message

- [ ] **Profile Management:**
  - [ ] Can view profile information
  - [ ] Can update profile fields
  - [ ] Changes are saved and reflected

### 5. Error Handling Test
- [ ] **Network Issues:**
  - [ ] App handles backend being offline
  - [ ] Appropriate error messages are shown
  - [ ] App doesn't crash on network errors

- [ ] **Image Loading:**
  - [ ] Placeholder shown for failed gym images
  - [ ] No crashes when images fail to load

- [ ] **Navigation:**
  - [ ] Back button works correctly from gym details
  - [ ] App state is maintained when switching tabs

## Performance Test
- [ ] App launches quickly
- [ ] Gym list scrolls smoothly
- [ ] Tab switching is responsive
- [ ] Image loading doesn't block UI
- [ ] No memory leaks during navigation

## Integration Test
- [ ] Backend and frontend communicate correctly
- [ ] JWT tokens are handled properly
- [ ] API responses are parsed correctly
- [ ] Authentication state is maintained across app restarts

## Final Verification
- [ ] All 5 navigation tabs work: Home, Workout, Nutrition, Community, **Gym Finder**
- [ ] Gym Finder is fully functional with search, filter, and details
- [ ] Authentication system works end-to-end
- [ ] No console errors or warnings
- [ ] App is ready for demonstration

---

**Note:** If any test fails, check the console logs and refer to the troubleshooting section in RUNNING_INSTRUCTIONS.md