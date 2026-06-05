/** 浅色 / 夜间模式配色 */
export class AppTheme {
  static pageBackground(isDark: boolean): string {
    return isDark ? '#121212' : '#FAFAFA';
  }

  static inputBarBackground(isDark: boolean): string {
    return isDark ? '#1E1E1E' : '#ECEFF1';
  }

  static inputBackground(isDark: boolean): string {
    return isDark ? '#2C2C2C' : '#FFFFFF';
  }

  static inputTextColor(isDark: boolean): string {
    return isDark ? '#FFFFFF' : '#212121';
  }

  static assistantBubble(isDark: boolean): string {
    return isDark ? '#1E1E1E' : '#FFFFFF';
  }

  static assistantText(isDark: boolean): string {
    return isDark ? '#E8E8E8' : '#212121';
  }

  static reasoningBackground(isDark: boolean): string {
    return isDark ? '#2A2A2A' : '#F5F5F5';
  }

  static reasoningText(isDark: boolean): string {
    return isDark ? '#B0B0B0' : '#757575';
  }

  static reasoningLabel(isDark: boolean): string {
    return isDark ? '#888888' : '#9E9E9E';
  }

  static secondaryText(isDark: boolean): string {
    return isDark ? '#9E9E9E' : '#666666';
  }

  static hintText(isDark: boolean): string {
    return isDark ? '#757575' : '#9E9E9E';
  }

  static cardBackground(isDark: boolean): string {
    return isDark ? '#1E1E1E' : '#FFFFFF';
  }

  static settingsPageBackground(isDark: boolean): string {
    return isDark ? '#121212' : '#F5F5F5';
  }

  static titleText(isDark: boolean): string {
    return isDark ? '#FFFFFF' : '#212121';
  }

  static descText(isDark: boolean): string {
    return isDark ? '#AAAAAA' : '#757575';
  }

  static inputFieldBackground(isDark: boolean): string {
    return isDark ? '#2C2C2C' : '#F5F5F5';
  }

  static sliderTrack(isDark: boolean): string {
    return isDark ? '#37474F' : '#E3F2FD';
  }
}
