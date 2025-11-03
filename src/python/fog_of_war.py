"""
Fog of War System for Turn-based Wumpus World
Manages visibility and exploration
"""

import pygame


class FogOfWar:
    """Fog of War system - limits player vision to nearby cells"""
    
    def __init__(self, grid_size=4, cell_size=147, prolog_engine=None):
        """
        Initialize fog of war system
        
        Args:
            grid_size: Size of the grid (4x4 default)
            cell_size: Pixel size of each cell
            prolog_engine: Prolog engine for querying visibility
        """
        self.grid_size = grid_size
        self.cell_size = cell_size
        self.prolog = prolog_engine
        
        # Visual surfaces
        self.fog_surface = pygame.Surface((cell_size, cell_size))
        self.fog_surface.fill((0, 0, 0))
        self.fog_surface.set_alpha(255)  # Completely dark
        
        self.dim_surface = pygame.Surface((cell_size, cell_size))
        self.dim_surface.fill((0, 0, 0))
        self.dim_surface.set_alpha(120)  # Semi-dark (previously explored)
    
    def is_visible(self, grid_x, grid_y):
        """Check if cell is currently visible (from Prolog)"""
        if self.prolog:
            result = list(self.prolog.query(f"is_visible({grid_x}, {grid_y})."))
            return len(result) > 0
        return True  # Fallback: show everything
    
    def is_revealed(self, grid_x, grid_y):
        """Check if cell has been revealed at some point (from Prolog)"""
        if self.prolog:
            result = list(self.prolog.query(f"is_revealed({grid_x}, {grid_y})."))
            return len(result) > 0
        return True  # Fallback: show everything
    
    def draw(self, surface, positions):
        """
        Draw fog of war overlay
        
        Args:
            surface: pygame surface to draw on
            positions: 2D array of cell positions [(x, y), ...]
        """
        for row in range(self.grid_size):
            for col in range(self.grid_size):
                grid_x = col + 1  # Prolog uses 1-indexed
                grid_y = row + 1
                
                pos = positions[col][row]
                
                if not self.is_revealed(grid_x, grid_y):
                    # Never seen - completely dark
                    surface.blit(self.fog_surface, pos)
                elif not self.is_visible(grid_x, grid_y):
                    # Seen before but not currently visible - dim
                    surface.blit(self.dim_surface, pos)
                # else: Currently visible - no overlay
    
    def draw_vision_indicator(self, surface, positions, hunter_pos):
        """
        Draw vision range indicator (optional debug)
        
        Args:
            surface: pygame surface to draw on
            positions: 2D array of cell positions
            hunter_pos: Hunter grid position (x, y)
        """
        # Draw subtle circle showing vision range
        hx, hy = hunter_pos
        if 1 <= hx <= 4 and 1 <= hy <= 4:
            center_pos = positions[hx-1][hy-1]
            center = (center_pos[0] + self.cell_size // 2, 
                     center_pos[1] + self.cell_size // 2)
            
            # Vision range circle (2 cells = ~294 pixels)
            vision_radius = self.cell_size * 2
            pygame.draw.circle(surface, (100, 100, 255, 50), center, vision_radius, 2)
