# 🤖 BrainCo Hand on Unitree G1 — Easy Setup Guide
---

## 📌 The Short Version

1. Copy the SDK to the G1
2. Download & install the USB driver
3. Unplug and replug the hand cable
4. Build the program
5. Run it 🎉

---

| Without the driver ❌ | With the driver ✅ |
|---|---|
| Hand shows up as `/dev/ttyACM0` | Hand shows up as `/dev/ttyCH343USB0` |
| Hand does **not** respond | Hand works |

So we must install the **WCH CH343 driver** once on every new robot.

---

## 1.clone the sdk

```bash
git clone https://github.com/kandelabhishek/brainco-hand-driver-sdk.git
```

---

## 2.Build the USB driver

```bash
ls ~/brainco-hand-sdk/tools/ch343ser_linux/driver
cd ~/brainco-hand-sdk/tools/ch343ser_linux/driver
make
```
#you can download the driver seperately from the link below

```bash
cd ~/brainco-hand-sdk/tools
git clone https://github.com/WCHSoftGroup/ch343ser_linux.git
```

---


### 3. Install it (so it loads every boot)

```bash
sudo make load
sudo make install
```

### 3.1 Stop the old driver from taking the hand

```bash
sudo rmmod cdc_acm
echo "blacklist cdc_acm" | sudo tee /etc/modprobe.d/blacklist-cdc_acm.conf
```

> If it says `Module cdc_acm is in use`, **unplug the hand cable first**, then run it again.

### 3.2 Unplug the hand adapter, wait 3 seconds, plug it back in

### 3.3 Check it worked

```bash
ls /dev/ttyCH343USB*
```

✅ You should see:

```
/dev/ttyCH343USB0  /dev/ttyCH343USB1  /dev/ttyCH343USB2
```

> `USB0` and `USB1` are the hands. `USB2` is something else on the robot — ignore it.

---

## Step 4 — Give yourself permission

```bash
sudo usermod -aG dialout $USER
```

Then **log out and SSH back in**:

```bash
exit
ssh unitree@<G1-IP>
```

---

## Step 5 — Build the program

```bash
cd ~/brainco-hand-sdk/c/demo
make clean
make
```
---

## Step 6 — Find which port is which hand

```bash
cd ~/brainco-hand-sdk/c/demo
for p in /dev/ttyCH343USB0 /dev/ttyCH343USB1; do
  for id in 126 127; do
    echo "== $p id=$id"
    sudo timeout 6 ./hand_demo.exe -m $p 460800 $id 2>&1 | grep -E "Device:|Failed to get" | head -1
  done
done
```

Look for lines that say `Device: Revo2 ...`:

```
== /dev/ttyCH343USB0 id=126
  Device: Revo2 Touch (Capacitive), SN: BCXTL...   ← LEFT hand ✅
== /dev/ttyCH343USB1 id=127
  Device: Revo2 Touch (Capacitive), SN: BCXTR...   ← RIGHT hand ✅
```

> 💡 `BCXT**L**` = Left, `BCXT**R**` = Right

Usually:

| Hand | Port | ID |
|---|---|---|
| Left Hand | `/dev/ttyCH343USB0` | `126` |
| Right Hand| `/dev/ttyCH343USB1` | `127` |

---

## Step 7 — Move the hand 🎉

### Basic command

```bash
sudo ./hand_demo.exe -m <PORT> 460800 <ID> <DEMO>
```

### Most useful commands

```bash
# Left hand
sudo ./hand_demo.exe -m /dev/ttyCH343USB0 460800 126 0

# Right hand 
sudo ./hand_demo.exe -m /dev/ttyCH343USB1 460800 127 0

```

### Demo list

| Number | What happens |
|---|---|
| *(nothing)* | Runs all demos |
| `1` | Make a fist, open hand, move one finger |
| `2` | Speed and force control |
| `3` | Advanced movements |
| `4` | Built-in gestures (fist, pinch, point…) |
| `5` | Show hand info (no movement) |
| `6` | Read touch sensors |
| `7` | **Open/close loop forever** |


## 🛠️ Problems & Fixes

| You see this | Do this |
|---|---|
| Only `/dev/ttyACM0`, no `ttyCH343USB` | Driver not active → redo **Step 3**, then unplug/replug |
| `timeout` / `Failed to get device info` | Wrong ID → swap `126` ↔ `127` |
| Command hangs, nothing happens | You're on `ttyACM` → install driver (**Step 3**) |
| `Failed to open Modbus port` | Wrong port, or you're on your **laptop** not the G1 (check prompt says `unitree@`) |
| `skipping incompatible libbc_stark_sdk.so` | Re-copy the full SDK from laptop (**Step 1**) |
| `auto_detect.exe: No such file` | Build failed → redo **Step 5** and read the error |
| `Failed to create log file: Permission denied` | Run with `sudo` |
| `make` fails in Step 3.1 | Kernel headers missing → ask Unitree for L4T headers |
| Hands stop working after reboot | Redo **Step 3.2** and **3.3** |
| Hand LED is off | Turn on the robot fully; check the cable |

---

## ⚠️ Don't Do This

- ❌ Don't run `./download-lib.sh` on the G1 — it fails and **deletes** the library folder.
- ❌ Don't use `/dev/ttyACM*` ports — they don't work with the hands.
- ❌ Don't use `/dev/ttyCH343USB2` — it's not a hand.

---

## 🚀 Lazy Mode (all-in-one script)

If the driver folder is already in `tools/` :

```bash
cd ~/brainco-hand-sdk
./tools/setup_g1_hand.sh
```

Then unplug/replug the hand, log out/in, and jump to **Step 6**.
