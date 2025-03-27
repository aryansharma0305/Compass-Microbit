# Micro:bit Compass Project (Assembly)

## Overview
This project implements a **digital compass** using the **BBC micro:bit** and assembly language. The compass reads **magnetic field data** from the built-in **magnetometer** and displays the direction on the micro:bit **LED matrix**.

---
## Features
✅ **Real-time Direction Detection** (N, E, S, W)  
✅ **LED Matrix Display** for Compass Directions  
---
## How It Works
1. **Initialize the Magnetometer** to read raw magnetic field values.
2. **Process the Data** to determine the heading angle.
3. **Map the Angle** to compass directions (e.g., N, E, S, W, etc.).
4. **Display the Direction** using **LED matrix patterns**.


---
## Compilation & Execution
### 🛠️ Assembling the Code
```sh
make
```

### ▶️ Flashing to Micro:bit
Convert the assembled file to a `.hex` format and flash it onto the Micro:bit using:
```sh
make upload
```

### 🧹 Cleaning Up
```sh
make clean
```

---
## Future Enhancements
- Add **tilt compensation** for more precise readings.
- Implement **Bluetooth connectivity** to display data on a phone.



<video width="600" controls>
  <source src="demo.mp4" type="video/mp4">
</video>
