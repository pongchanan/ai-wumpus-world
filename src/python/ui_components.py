"""
UI Components for Enhanced Turn-based Wumpus World
"""

import pygame
import os


class InventoryDisplay:
    """Display player inventory (arrows, rocks, health)"""
    
    def __init__(self, font_path, prolog_engine=None):
        # Load font
        try:
            self.font = pygame.font.Font(font_path, 20)
        except:
            self.font = pygame.font.Font(None, 20)  # Default font
        
        self.prolog = prolog_engine
        
        # Load icons (copy from main game assets)
        self.load_icons()
    
    def load_icons(self):
        """Load item icons"""
        # Simple placeholder - can replace with actual sprites
        self.arrow_icon = pygame.Surface((20, 20))
        self.arrow_icon.fill((200, 200, 0))
        
        self.rock_icon = pygame.Surface((20, 20))
        self.rock_icon.fill((150, 150, 150))
        
        self.heart_icon = pygame.Surface((20, 20))
        self.heart_icon.fill((255, 50, 50))
    
    def get_inventory(self):
        """Get current inventory from Prolog"""
        if not self.prolog:
            return {'arrows': 1, 'rocks': 2, 'health': 100}
        
        try:
            arrows_result = list(self.prolog.query("h_arrow(A)."))
            arrows = arrows_result[0]['A'] if arrows_result else 0
            
            rocks_result = list(self.prolog.query("h_rocks(R)."))
            rocks = rocks_result[0]['R'] if rocks_result else 0
            
            # Health is represented by score penalties (simplified)
            score_result = list(self.prolog.query("h_score(S)."))
            score = score_result[0]['S'] if score_result else 0
            
            return {'arrows': arrows, 'rocks': rocks, 'score': score}
        except:
            return {'arrows': 0, 'rocks': 0, 'score': 0}
    
    def draw(self, surface, position=(10, 10)):
        """Draw inventory display"""
        inv = self.get_inventory()
        x, y = position
        
        # Background panel
        panel_width = 250
        panel_height = 100
        panel = pygame.Surface((panel_width, panel_height), pygame.SRCALPHA)
        panel.fill((0, 0, 0, 180))
        surface.blit(panel, (x, y))
        
        # Arrows
        text_arrows = self.font.render(f"Arrows: {inv['arrows']}", True, (255, 255, 255))
        surface.blit(text_arrows, (x + 10, y + 10))
        
        # Rocks
        text_rocks = self.font.render(f"Rocks: {inv['rocks']}", True, (255, 255, 255))
        surface.blit(text_rocks, (x + 10, y + 40))
        
        # Score
        text_score = self.font.render(f"Score: {inv['score']}", True, (255, 255, 0))
        surface.blit(text_score, (x + 10, y + 70))


class RockAimingOverlay:
    """Visual overlay for rock throwing"""
    
    def __init__(self, positions, cell_size=147, prolog_engine=None, font_path=None):
        self.positions = positions
        self.cell_size = cell_size
        self.prolog = prolog_engine
        self.aiming = False
        self.valid_targets = []
        self.selected_target = None
        self.selected_index = 0
        
        # Load font
        try:
            self.font = pygame.font.Font(font_path, 24)
        except:
            self.font = pygame.font.Font(None, 24)  # Default font
    
    def start_aiming(self, hunter_grid_pos):
        """Begin aiming mode"""
        self.aiming = True
        self.valid_targets = self.calculate_throwable_cells(hunter_grid_pos)
        if self.valid_targets:
            self.selected_index = 0
            self.selected_target = self.valid_targets[0]
        else:
            self.aiming = False
    
    def calculate_throwable_cells(self, hunter_pos):
        """Calculate cells player can throw to (1-4 manhattan distance)"""
        valid = []
        hx, hy = hunter_pos
        
        for dx in range(-4, 5):
            for dy in range(-4, 5):
                dist = abs(dx) + abs(dy)
                if 1 <= dist <= 4:
                    tx = hx + dx
                    ty = hy + dy
                    if 1 <= tx <= 4 and 1 <= ty <= 4:  # Valid grid
                        valid.append((tx, ty))
        
        return valid
    
    def cycle_target(self, direction):
        """Cycle through valid targets (1 = next, -1 = previous)"""
        if not self.valid_targets:
            return
        
        self.selected_index = (self.selected_index + direction) % len(self.valid_targets)
        self.selected_target = self.valid_targets[self.selected_index]
    
    def confirm_throw(self):
        """Confirm rock throw to selected target"""
        if not self.selected_target:
            return False
        
        tx, ty = self.selected_target
        
        # Execute throw in Prolog
        if self.prolog:
            try:
                list(self.prolog.query(f"throw_rock({tx}, {ty})."))
                self.aiming = False
                return True
            except:
                print(f"Failed to throw rock to ({tx}, {ty})")
                return False
        
        self.aiming = False
        return True
    
    def cancel(self):
        """Cancel aiming"""
        self.aiming = False
        self.selected_target = None
    
    def draw(self, surface, font):
        """Draw aiming overlay (font parameter ignored, uses self.font)"""
        if not self.aiming:
            return
        
        # Draw valid targets (green circles)
        for tx, ty in self.valid_targets:
            pos = self.positions[tx-1][ty-1]
            center = (pos[0] + self.cell_size // 2, pos[1] + self.cell_size // 2)
            pygame.draw.circle(surface, (0, 255, 0), center, 20, 3)
        
        # Draw selected target (red circle + crosshair)
        if self.selected_target:
            tx, ty = self.selected_target
            pos = self.positions[tx-1][ty-1]
            center = (pos[0] + self.cell_size // 2, pos[1] + self.cell_size // 2)
            
            # Red circle
            pygame.draw.circle(surface, (255, 0, 0), center, 25, 5)
            
            # Crosshair
            pygame.draw.line(surface, (255, 0, 0), 
                           (center[0] - 15, center[1]), 
                           (center[0] + 15, center[1]), 3)
            pygame.draw.line(surface, (255, 0, 0), 
                           (center[0], center[1] - 15), 
                           (center[0], center[1] + 15), 3)
            
            # Target coordinates
            coord_text = self.font.render(f"Target: ({tx}, {ty})", True, (255, 255, 255))
            text_rect = coord_text.get_rect(center=(center[0], center[1] + 50))
            surface.blit(coord_text, text_rect)
        
        # Instructions
        instructions = [
            "Rock Throwing Mode",
            "Arrow Keys: Select target",
            "SPACE: Throw rock",
            "ESC: Cancel"
        ]
        
        y_offset = 10
        for instruction in instructions:
            text = self.font.render(instruction, True, (255, 255, 255))
            text_rect = text.get_rect(center=(surface.get_width() // 2, y_offset))
            
            # Background
            bg_rect = text_rect.inflate(20, 10)
            bg_surface = pygame.Surface(bg_rect.size, pygame.SRCALPHA)
            bg_surface.fill((0, 0, 0, 200))
            surface.blit(bg_surface, bg_rect.topleft)
            
            # Text
            surface.blit(text, text_rect)
            y_offset += 30


class TurnIndicator:
    """Display current turn information"""
    
    def __init__(self, font_path, prolog_engine=None):
        # Load font
        try:
            self.font = pygame.font.Font(font_path, 20)
        except:
            self.font = pygame.font.Font(None, 20)  # Default font
        
        self.prolog = prolog_engine
        self.turn_count = 0
    
    def increment_turn(self):
        """Increment turn counter"""
        self.turn_count += 1
    
    def get_wumpus_state(self):
        """Get Wumpus AI state from Prolog"""
        if not self.prolog:
            return "Unknown"
        
        try:
            result = list(self.prolog.query("wumpus_state(1, State)."))
            if result:
                return result[0]['State']
        except:
            pass
        
        return "Unknown"
    
    def is_player_stunned(self):
        """Check if player is stunned"""
        if not self.prolog:
            return False
        
        try:
            result = list(self.prolog.query("is_player_stunned."))
            return len(result) > 0
        except:
            return False
    
    def draw(self, surface, position=(10, 650)):
        """Draw turn indicator"""
        x, y = position
        
        # Turn count
        turn_text = self.font.render(f"Turn: {self.turn_count}", True, (255, 255, 255))
        surface.blit(turn_text, (x, y))
        
        # Wumpus state
        wumpus_state = self.get_wumpus_state()
        state_color = (255, 255, 0) if wumpus_state in ['chasing', 'investigating'] else (100, 255, 100)
        state_text = self.font.render(f"Wumpus: {wumpus_state}", True, state_color)
        surface.blit(state_text, (x, y + 30))
        
        # Stun warning
        if self.is_player_stunned():
            stun_text = self.font.render("⚠️ STUNNED!", True, (255, 0, 0))
            surface.blit(stun_text, (x + 200, y))
