
    # 3. Generic
    return GENERIC_FOOD
 URL for a food item.
    Checks specific multi-word names before single-word ones to avoid
    e.g. 'apple' matching 'apple juice' or 'apple pie'.
    """
    name_lower = food_name.lower().strip()

    # 1. Specific match (ordered list — longer/more specific first)
    for keyword, url in FOOD_IMAGE_LIST:
        if keyword in name_lower:
            return url

    # 2. Category fallback
    for keywords, url in CATEGORY_FALLBACKS:
        if any(k in name_lower for k in keywords):
            return url
407-f5e1ad6d020b?w=300'),
    (['dairy'],
     'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=300'),
    (['drink', 'juice', 'beverage'],
     'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=300'),
    (['dessert', 'sweet', 'snack'],
     'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=300'),
]

GENERIC_FOOD = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300'


def get_food_image_url(food_name: str) -> str:
    """
    Returns the most specific matching image6-fcd25c85cd64?w=300'),
]

# Category fallbacks (checked if no specific match found)
CATEGORY_FALLBACKS = [
    (['fruit', 'berry', 'melon'],
     'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=300'),
    (['vegetable', 'veggie', 'greens'],
     'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300'),
    (['meat', 'protein'],
     'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=300'),
    (['grain', 'cereal', 'flour'],
     'https://images.unsplash.com/photo-1574323347        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('sauce',           'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('ketchup',         'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('mayonnaise',      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('mustard',         'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('vinegar',         'https://images.unsplash.com/photo-155861866o-1508747703725-719777637510?w=300'),

    # ── Oils & Condiments ────────────────────────────────────────────────────
    ('olive oil',       'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300'),
    ('oil',             'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300'),
    ('honey',           'https://images.unsplash.com/photo-1587049352846-4a222e784422?w=300'),
    ('sugar',           'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('salt',           'https://images.unsplash.com/photo-1508747703725-719777637510?w=300'),
    ('chia seed',       'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=300'),
    ('flaxseed',        'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=300'),
    ('sunflower seed',  'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=300'),
    ('seed',            'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=300'),
    ('nut',             'https://images.unsplash.com/phot──────────────────────────────
    ('almond',          'https://images.unsplash.com/photo-1508747703725-719777637510?w=300'),
    ('walnut',          'https://images.unsplash.com/photo-1508747703725-719777637510?w=300'),
    ('peanut butter',   'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('peanut',          'https://images.unsplash.com/photo-1582037928769-181f2644ecb7?w=300'),
    ('cashew',          'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=300'),
    ('pistachio',',            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300'),
    ('cheddar',         'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=300'),
    ('cheese',          'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=300'),
    ('butter',          'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=300'),
    ('cream',           'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=300'),

    # ── Nuts & Seeds ───────────────────────────-1550583724-b2692b85b150?w=300'),
    ('whole milk',      'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300'),
    ('milk',            'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300'),
    ('greek yogurt',    'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300'),
    ('yogurt',          'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300'),
    ('dahi',            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300'),
    ('curd ('quinoa',          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300'),
    ('cereal',          'https://images.unsplash.com/photo-1590137876181-b26f0a10e0d3?w=300'),
    ('granola',         'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=300'),
    ('tortilla',        'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=300'),

    # ── Dairy ────────────────────────────────────────────────────────────────
    ('skim milk',       'https://images.unsplash.com/photo/photo-1509440159596-0249088772ff?w=300'),
    ('white bread',     'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300'),
    ('bread',           'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300'),
    ('pasta',           'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=300'),
    ('oatmeal',         'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=300'),
    ('oat',             'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=300'),
   ),
    ('dal',             'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=300'),

    # ── Grains & Bread ───────────────────────────────────────────────────────
    ('brown rice',      'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=300'),
    ('white rice',      'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=300'),
    ('rice',            'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=300'),
    ('whole wheat bread','https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=300'),
    ('egg',             'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=300'),
    ('tofu',            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300'),
    ('lentil',          'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=300'),
    ('chickpea',        'https://images.unsplash.com/photo-1589367920969-ab8e050bbb04?w=300'),
    ('beans',           'https://images.unsplash.com/photo-1589367920969-ab8e050bbb04?w=300'',          'https://images.unsplash.com/photo-1574672280600-4accfa5b6f98?w=300'),
    ('lamb',            'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=300'),
    ('salmon',          'https://images.unsplash.com/photo-1485921325833-c519f76c4927?w=300'),
    ('tuna',            'https://images.unsplash.com/photo-1580959375944-0b7b9e7d1e5e?w=300'),
    ('shrimp',          'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=300'),
    ('fish',            'https://images.unsplash.comphoto-1551754655-cd27e38d2076?w=300'),
    ('radish',          'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?w=300'),

    # ── Proteins ─────────────────────────────────────────────────────────────
    ('chicken',         'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=300'),
    ('beef',            'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=300'),
    ('pork',            'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=300'),
    ('turkeyggplant',        'https://images.unsplash.com/photo-1659261200833-ec8761558af7?w=300'),
    ('corn',            'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=300'),
    ('peas',            'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?w=300'),
    ('garlic',          'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?w=300'),
    ('ginger',          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=300'),
    ('celery',          'https://images.unsplash.com/o-1565688534245-05d6b5be184a?w=300'),
    ('cauliflower',     'https://images.unsplash.com/photo-1568584711271-e88a6c3d6b8e?w=300'),
    ('cabbage',         'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=300'),
    ('kale',            'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=300'),
    ('asparagus',       'https://images.unsplash.com/photo-1550870405-6a0f8df07f8c?w=300'),
    ('zucchini',        'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=300'),
    ('eages.unsplash.com/phot?w=300'),
    ('pepper',          'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=300'),
    ('lettuce',         'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=300'),
    ('onion',           'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=300'),
    ('sweet potato',    'https://images.unsplash.com/photo-1596097635121-14b63b7a0c19?w=300'),
    ('potato',          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=300'),
    ('mushroom',        'https://imges.unsplash.com/photo-1459411621453-7b03977f4bfc?w=300'),
    ('carrot',          'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=300'),
    ('spinach',         'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=300'),
    ('tomato',          'https://images.unsplash.com/photo-1546470427-227e9e3e0e4e?w=300'),
    ('cucumber',        'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=300'),
    ('bell pepper',     'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83a9be46?w=300'),
    ('papaya',          'https://images.unsplash.com/photo-1526318896980-cf78c088247c?w=300'),
    ('pomegranate',     'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=300'),
    ('fig',             'https://images.unsplash.com/photo-1601379327928-bedfaf9da2d0?w=300'),
    ('date',            'https://images.unsplash.com/photo-1601379327928-bedfaf9da2d0?w=300'),

    # ── Vegetables ───────────────────────────────────────────────────────────
    ('broccoli',        'https://imamages.unsplash.com/photo-1528821128474-27f963b062bf?w=300'),
    ('kiwi',            'https://images.unsplash.com/photo-1585059895524-72359e06133a?w=300'),
    ('avocado',         'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=300'),
    ('lemon',           'https://images.unsplash.com/photo-1590502593747-42a996133562?w=300'),
    ('lime',            'https://images.unsplash.com/photo-1582169296194-e4d644c48063?w=300'),
    ('coconut',         'https://images.unsplash.com/photo-1559181567-c3190c22e784422?w=300'),
    ('mango',           'https://images.unsplash.com/photo-1553279768-865429fa0078?w=300'),
    ('pineapple',       'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=300'),
    ('blueberry',       'https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=300'),
    ('peach',           'https://images.unsplash.com/photo-1629828874514-d05e24e0c32f?w=300'),
    ('pear',            'https://images.unsplash.com/photo-1568471173238-64ed8e7e9d6e?w=300'),
    ('cherry',          'https://ies.unsplash.com/photo-1568702846914-96b305d2aaeb?w=300'),
    ('banana',          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300'),
    ('orange',          'https://images.unsplash.com/photo-1580052614034-c55d20bfee3b?w=300'),
    ('strawberry',      'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=300'),
    ('grape',           'https://images.unsplash.com/photo-1599819177626-c0d3b8d6c7e1?w=300'),
    ('watermelon',      'https://images.unsplash.com/photo-1587049352846-4a2://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=300'),
    ('steak',           'https://images.unsplash.com/photo-1546964124-0cce460f38ef?w=300'),

    # ── Fruits (single) ──────────────────────────────────────────────────────
    ('apple',           'https://imag?w=300'),
    ('stew',            'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=300'),
    ('curry',           'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=300'),
    ('noodle',          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300'),
    ('sushi',           'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=300'),
    ('taco',            'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=300'),
    ('wrap',            'httpss.unsplash.com/photo-1516684732162-798a0062be99?w=300'),
    ('burger',          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300'),
    ('pizza',           'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300'),
    ('sandwich',        'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=300'),
    ('salad',           'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300'),
    ('soup',            'https://images.unsplash.com/photo-1547592166-23ac45744acd300'),
    ('chana masala',    'https://images.unsplash.com/photo-1585937421612-70e008356f33?w=300'),
    ('paneer',          'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=300'),
    ('paratha',         'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=300'),
    ('naan',            'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300'),
    ('roti',            'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=300'),
    ('chiura',          'https://image045057995-568f588f82fb?w=300'),
    ('samosa',          'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=  'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300'),
    ('thukpa',          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300'),
    ('yomari',          'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300'),
    ('bara',            'https://images.unsplash.com/photo-1630383249896-424e482df921?w=300'),
    ('dhido',           'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=300'),
    ('gundruk',         'https://images.unsplash.com/photo-1576585032226651-759b368d7246?w=300'),
    ('chatamari',       'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=300'),
    ('fried egg',       'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=300'),
    ('omelette',        'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=300'),
    ('momo',            'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=300'),
    ('sel roti',        'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300'),
    ('aloo tama',       'https://images.unsplash.com/photo-1'),
    ('scrambled egg',   'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=300'),
    ('boiled egg',    h.com/photo-1604503468506-a8da13d82791?w=300'),
    ('chicken wings',   'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=300'),
    ('chicken soup',    'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=300'),
    ('beef steak',      'https://images.unsplash.com/photo-1546964124-0cce460f38ef?w=300'),
    ('beef burger',     'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300'),
    ('pork chop',       'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=30023262-b51c2513a641?w=300'),
    ('chicken breast',  'https://images.unsplas           'https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=300'),
    ('dessert',         'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=300'),

    # ── Prepared dishes (before ingredient names) ────────────────────────────
    ('dal bhat',        'https://images.unsplash.com/photo-1585937421612-70e008356f33?w=300'),
    ('fried rice',      'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=300'),
    ('chicken curry',   'https://images.unsplash.com/photo-15655576   ('chocolate',       'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=300'),
    ('candy',/photo-1499636136210-6f4ee915583e?w=300'),
    ('brownie',         'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=300'),
    ('ice cream',       'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=300'),
    ('pudding',         'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=300'),
    ('cake',            'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300'),
    ('pie',             'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=300'),
 036-ab1f4038808a?w=300'),
    ('cookie',          'https://images.unsplash.com    'https://images.unsplash.com/photo-1621303837174-89787a7d4729?w=300'),
    ('pancake',         'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=300'),
    ('waffle',          'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=300'),
    ('donut',           'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=300'),
    ('muffin',          'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=300'),
    ('croissant',       'https://images.unsplash.com/photo-1555507, 587?w=300'),
    ('cheesecake',      'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=300'),
    ('carrot cake'ash.com/photo-1568571780765-9276ac8b75a2?w=300'),
    ('banana bread',    'https://images.unsplash.com/photo-1605286978633-2dec93ff88a2?w=300'),
    ('banana cake',     'https://images.unsplash.com/photo-1605286978633-2dec93ff88a2?w=300'),
    ('mango cake',      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300'),
    ('strawberry cake', 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=300'),
    ('chocolate cake',  'https://images.unsplash.com/photo-1578985545062-69928b1d999bbe4?w=300'),
    ('soda',            'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=300'),
    ('juice',           'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=300'),
    ('tea',             'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=300'),

    # ── Baked goods / Desserts (before fruit/grain names) ───────────────────
    ('apple pie',       'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=300'),
    ('apple cake',      'https://images.unspl,           'https://images.unsplash.com/photo-1623065422902-30a2d261336313-0bd5e0b27ec8?w=300'),
    ('coffee',          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300'),
    ('smoothie',        'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=300'),
    ('lassi'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=300'),
    ('black tea',       'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=300'),
    ('milk tea',        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
    ('chai',            'https://images.unsplash.com/photo-15ice',    'https://images.unsplash.com/photo-1571680322279-a226e6a4cc2a?w=300'),
    ('coconut water',   'https://images.unsplash.com/photo-1559181567-c3190ca9be46?w=300'),
    ('green tea',       'plash.com/photo-1556679343-c7306c1976bc?w=300'),
    ('pineapple juice', 'https://images.unsplash.com/photo-1546173159-315724a31696?w=300'),
    ('tomato juhttps://images.unsplash.com/photo-1600271886742-f049cd451bba?w=300'),
    ('orange juice',    'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=300'),
    ('mango juice',     'https://images.unsplash.com/photo-1546173159-315724a31696?w=300'),
    ('grape juice',     'https://images.unsplash.com/photo-1596803244897-e4e5e5e5e5e5?w=300'),
    ('lemon juice',     'https://images.uns
    ('apple juice',     'irst match wins.
All URLs are Unsplash (free, no API key needed).
"""

# Each entry: (keyword_to_match, image_url)
# Checked in ORDER — put specific multi-word names BEFORE single-word ones.
FOOD_IMAGE_LIST = [

    # ── Juices & Drinks (must come before fruit names) ──────────────────────ames MUST come before shorter ones.
e.g. 'apple juice' before 'apple', 'apple pie' before 'apple'.
The list is checked in order — f"""
Food image URL mapping.
IMPORTANT: More specific / longer n