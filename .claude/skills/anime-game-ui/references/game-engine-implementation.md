# Game Engine UI Implementation Guide

แนวทางการจัดวางโครงสร้าง UI (Node Tree & Component Hierarchy) สำหรับเอนจินเกมยอดนิยม

---

## 1. Godot Engine 4 (Control Node Tree)

ใน Godot 4 ให้ใช้ระบบ `Control` ร่วมกับ `Containers` เพื่อรองรับหน้าจอความละเอียดต่างกัน (16:9, จอมือถือ, จอ Ultrawide)

```text
CombatHUD (CanvasLayer)
├── SafeScreenMargin (MarginContainer) [Anchor: Full Rect, Margin: 24px]
│   ├── TopHUD (HBoxContainer) [Anchor: Top Wide]
│   │   ├── TimelineQueue (HBoxContainer)
│   │   │   ├── TimelineUnitPortrait (TextureRect + ShaderMaterial)
│   │   │   └── ...
│   │   └── TopRightControls (HBoxContainer)
│   │       ├── WaveLabel (Label)
│   │       └── PauseBtn (TextureButton)
│   │
│   ├── TargetContainer (VBoxContainer) [Anchor: Top Center, OffsetY: 80px]
│   │   ├── TargetNameLabel (Label)
│   │   ├── TargetHealthBar (ProgressBar)
│   │   └── TargetStaggerBar (ProgressBar)
│   │
│   └── BottomHUD (HBoxContainer) [Anchor: Bottom Wide]
│       ├── PartyStatusContainer (HBoxContainer) [SizeFlags: Expand]
│       │   ├── CharacterCard_Ren (Control)
│       │   │   ├── AvatarTexture (TextureRect)
│       │   │   ├── CoreSealVFX (ColorRect with SealShader)
│       │   │   ├── HealthBar (ProgressBar)
│       │   │   └── BreathBar (ProgressBar)
│       │   ├── CharacterCard_Oli (Control)
│       │   └── CharacterCard_Null (Control)
│       │
│       └── ActionDeck (VBoxContainer) [Alignment: End]
│           ├── SkillButtonsGrid (GridContainer - 2x3 slots)
│           │   ├── SkillBtn_1 (TextureButton)
│           │   └── ...
│           └── ThreeSecondsBurstBtn (TextureButton - Glow Animation)
```

---

## 2. Unity (UGUI / Canvas Hierarchy)

ใน Unity ให้ตั้งค่า `CanvasScaler` เป็น **Scale With Screen Size** (Reference Resolution: `1920x1080`, Match: `0.5` ระหว่าง Width และ Height)

```text
[GameObject] Canvas_CombatHUD (Canvas & GraphicRaycaster)
├── [GameObject] ScreenSafeArea (RectTransform - Managed by SafeArea script)
│   ├── [Panel] TurnTimeline_Bar (HorizontalLayoutGroup)
│   │   └── [Prefab] Timeline_Entry (Image, TextMeshProUGUI)
│   ├── [Panel] Boss_TargetInfo (VerticalLayoutGroup)
│   │   ├── [Text] Txt_BossName
│   │   ├── [Slider] Sldr_HealthBar
│   │   └── [Slider] Sldr_StaggerBar
│   ├── [Panel] Party_Dock (HorizontalLayoutGroup)
│   │   ├── [Prefab] PartyMember_Slot (Ren)
│   │   │   ├── Img_Avatar
│   │   │   ├── Img_CoreSeal (Custom Material with ShaderGraph)
│   │   │   ├── Slider_HP
│   │   │   └── Slider_Breath
│   │   └── ...
│   └── [Panel] Skill_CommandWheel (RectTransform with Animator)
│       ├── Btn_NormalAttack
│       ├── Btn_Skill1
│       ├── Btn_Skill2
│       └── Btn_Special_3Secs (ParticleSystem UI overlay)
```

---

## 3. WebGL / Canvas / Pixi.js (สำหรับ Web Game & Mini App)

สำหรับทำ Prototype บนเบราว์เซอร์ด้วย Pixi.js หรือ Phaser:

```javascript
// โครงสร้าง Container Hierarchy ใน Pixi.js
const hudStage = new PIXI.Container();

// 1. Timeline Container
const timelineContainer = new PIXI.Container();
timelineContainer.position.set(40, 20);
hudStage.addChild(timelineContainer);

// 2. Party Status Container
const partyContainer = new PIXI.Container();
partyContainer.position.set(40, app.screen.height - 180);
hudStage.addChild(partyContainer);

// 3. Command Deck Container
const commandDeck = new PIXI.Container();
commandDeck.position.set(app.screen.width - 320, app.screen.height - 240);
hudStage.addChild(commandDeck);

// อัปเดตตำแหน่งเมื่อหน้าจอถูก Resize
window.addEventListener('resize', () => {
    partyContainer.y = app.screen.height - 180;
    commandDeck.x = app.screen.width - 320;
    commandDeck.y = app.screen.height - 240;
});
```
