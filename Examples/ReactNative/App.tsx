// App.tsx - Correct import for react-native-sfsymbols
import React, { useEffect } from 'react';
import {
  View,
  StyleSheet,
  Dimensions,
  Animated,
} from 'react-native';

import { SFSymbol } from 'react-native-sfsymbols';

const { width, height } = Dimensions.get('window');

const App = () => {
  const opacity = new Animated.Value(0);
  const scale = new Animated.Value(0.5);

  const icons = ['photo.fill', 'camera.fill', 'star.fill'];
  
  const positions = [
    { x: width / 2, y: height * 0.3 },
    { x: width / 2, y: height * 0.5 },
    { x: width / 2, y: height * 0.7 },
  ];

  useEffect(() => {
    Animated.parallel([
      Animated.timing(opacity, {
        toValue: 1,
        duration: 1000,
        useNativeDriver: true,
      }),
      Animated.timing(scale, {
        toValue: 1,
        duration: 1000,
        useNativeDriver: true,
      }),
    ]).start();
  }, []);

  return (
    <View style={styles.container}>
      {icons.map((iconName, index) => (
        <Animated.View
          key={index}
          style={[
            styles.iconContainer,
            {
              left: positions[index].x - 50,
              top: positions[index].y - 50,
              opacity: opacity,
              transform: [{ scale: scale }],
            },
          ]}
        >
          <SFSymbol
            name={iconName}
            size={50}
            color="white"
          />
        </Animated.View>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'black',
  },
  iconContainer: {
    position: 'absolute',
    width: 100,
    height: 100,
    backgroundColor: 'rgba(0, 0, 255, 0.3)',
    borderRadius: 12,
    borderWidth: 2,
    borderColor: 'white',
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;