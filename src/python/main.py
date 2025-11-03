import sys
import pygame
import argparse
import math

from pyswip import Prolog
from utils import rotate
from date import (
    PROLOG_PATH, FPS, WIN, FONT,
    MAP, LIGHT, WIDTH, HEIGHT, POSITIONS,
    HUNTER_IDLE, HUNTER_MOVE, HUNTER_SHOOT,
    WUMPUS_IDLE, WUMPUS_BLOOD, GOLD, PIT,
    W_BS, W_BREEZE, W_STENCH, W_GOLD, EXIT
)

# Import new UI components
from fog_of_war import FogOfWar
from ui_components import InventoryDisplay, RockAimingOverlay, TurnIndicator

prolog = Prolog()
prolog.consult(PROLOG_PATH)


class element:
    """class to save element position and draw it"""

    def __init__(self, y, x):
        self.x, self.y = POSITIONS[x-1][y-1]

    def draw(self):
        self.rect = self.image.get_rect(center=(self.x, self.y))
        WIN.blit(self.image, self.rect)


class Light():
    """class to draw the light effect on the hunter position"""

    def __init__(self):
        self.x, self.y = 0, 0
        self.image = LIGHT
        self.filter = pygame.surface.Surface((WIDTH, HEIGHT))
        self.filter.fill(pygame.color.Color('white'))
        self.visited = []

    def update(self, hunter_obj):
        new_coords = (hunter_obj.x, hunter_obj.y)
        if new_coords not in self.visited and new_coords != (self.x, self.y):
            self.x, self.y = new_coords
            light_pos = (self.x, self.y)
            self.rect = self.image.get_rect(center=light_pos)
            self.visited.append(new_coords)
        else:
            self.rect = pygame.Rect(-999, -999, 0, 0)

    def draw(self):
        self.filter.blit(self.image, self.rect)
        WIN.blit(self.filter, (0, 0), special_flags=pygame.BLEND_RGBA_SUB)


class Hunter(element, pygame.sprite.Sprite):
    """class with the hunter information"""

    def __init__(self, x, y, orientation):
        element.__init__(self, x, y)
        pygame.sprite.Sprite.__init__(self)
        self.rotation = orientation
        self.sprites = {
            'idle': HUNTER_IDLE,
            'move': HUNTER_MOVE,
            'shoot': HUNTER_SHOOT
        }
        self.anim_speed = 1
        self.current_sprite = 0
        self.current_state = 'idle'
        self.image = self.sprites[self.current_state][self.current_sprite]

        self.rect = self.image.get_rect()
        self.rect.center = (self.x, self.y)

        self.facing_angle = {'right': 0, 'up': 90, 'left': 180, 'down': -90}

    def move(self, y, x, facing):
        self.rotation = facing
        self.image = rotate(self.image, self.facing_angle[facing])
        self.x, self.y = POSITIONS[x-1][y-1]

        self.rect = self.image.get_rect()
        self.rect.center = (self.x, self.y)

    def update(self):
        self.current_sprite += self.anim_speed
        if self.current_sprite >= len(self.sprites[self.current_state]):
            self.current_sprite = 0
        self.image = self.sprites[self.current_state][int(self.current_sprite)]

        new_pos = list(prolog.query("w_hunter( X, Y, Z)."))[0].values()
        self.move(*new_pos)


class Wumpus(element, pygame.sprite.Sprite):
    """class with the wumpus information"""

    def __init__(self, x, y):
        element.__init__(self, x, y)
        pygame.sprite.Sprite.__init__(self)
        self.sprites = {
            'idle': WUMPUS_IDLE,
            'died': WUMPUS_BLOOD
        }
        self.anim_speed = 1
        self.current_sprite = 0
        self.current_state = 'idle'
        self.image = self.sprites[self.current_state][self.current_sprite]

        self.rect = self.image.get_rect()
        self.rect.center = (self.x, self.y)

    def update(self):
        if not list(prolog.query('w_wumpus(X,Y).')) and self.x != self.y != -999:
            self.x, self.y = (-999, -999)

        self.current_sprite += self.anim_speed
        if self.current_sprite >= len(self.sprites[self.current_state]):
            self.current_sprite = 0
        self.image = self.sprites[self.current_state][int(self.current_sprite)]

        self.rect = self.image.get_rect()
        self.rect.center = (self.x, self.y)


class Pit(element, pygame.sprite.Sprite):
    """class with the pit information"""

    def __init__(self, x, y):
        super().__init__(x, y)
        self.image = PIT


class Gold(element, pygame.sprite.Sprite):
    """class with the gold information"""

    def __init__(self, x, y):
        super().__init__(x, y)
        self.image = GOLD

    def update(self):
        if list(prolog.query('w_gold(0,0).')) and self.x != self.y != -999:
            self.x, self.y = (-999, -999)

    def draw(self):
        self.rect = self.image.get_rect(center=(self.x, self.y))
        WIN.blit(self.image, self.rect)

        if self.x == self.y == -999:
            WIN.blit(EXIT, (0, 0))


class TreasureChest(element, pygame.sprite.Sprite):
    """Treasure chest that could be real or mimic"""
    
    def __init__(self, chest_id, x, y):
        super().__init__(x, y)
        self.chest_id = chest_id
        self.opened = False
        
        # Get type from Prolog
        chest_info = list(prolog.query(f"chest({chest_id}, _, _, Type)."))
        self.is_mimic = chest_info[0]['Type'] == 'mimic' if chest_info else False
        
        # Animation
        self.shake_timer = 0
        self.shake_offset = 0
        
        # Create chest image
        self.create_chest_image()
    
    def create_chest_image(self):
        """Draw chest sprite"""
        size = 40
        self.image = pygame.Surface((size, size), pygame.SRCALPHA)
        
        if self.opened:
            # Open chest
            pygame.draw.rect(self.image, (139, 69, 19), (5, 20, 30, 15))
            if not self.is_mimic:
                # Show gold
                pygame.draw.circle(self.image, (255, 215, 0), (20, 27), 8)
        else:
            # Closed chest (brown box)
            pygame.draw.rect(self.image, (139, 69, 19), (5, 15, 30, 20))
            pygame.draw.rect(self.image, (101, 67, 33), (5, 10, 30, 10))
            pygame.draw.rect(self.image, (218, 165, 32), (18, 20, 4, 6))
            
            # Mimic has slight red tint and shake
            if self.is_mimic:
                red_tint = pygame.Surface((size, size), pygame.SRCALPHA)
                red_tint.fill((255, 0, 0, 30))
                self.image.blit(red_tint, (0, 0))
        
        self.rect = self.image.get_rect(center=(self.x, self.y))
    
    def update(self):
        """Update chest (shake for mimics)"""
        # Check if opened
        opened_result = list(prolog.query(f"chest_opened({self.chest_id})."))
        self.opened = len(opened_result) > 0
        
        if not self.opened and self.is_mimic:
            self.shake_timer += 0.1
            self.shake_offset = math.sin(self.shake_timer * 10) * 2
        else:
            self.shake_offset = 0
        
        # Update position from Prolog (mimics can move)
        chest_info = list(prolog.query(f"chest({self.chest_id}, X, Y, _)."))
        if chest_info:
            new_x, new_y = chest_info[0]['X'], chest_info[0]['Y']
            self.x, self.y = POSITIONS[new_x-1][new_y-1]
            self.x += self.shake_offset
        
        self.create_chest_image()
    
    def draw(self):
        self.rect = self.image.get_rect(center=(self.x, self.y))
        WIN.blit(self.image, self.rect)


class RockPickup(element, pygame.sprite.Sprite):
    """Rock pickup item"""
    
    def __init__(self, x, y):
        super().__init__(x, y)
        
        # Create rock image
        size = 30
        self.image = pygame.Surface((size, size), pygame.SRCALPHA)
        pygame.draw.circle(self.image, (150, 150, 150), (size//2, size//2), size//2 - 2)
        pygame.draw.circle(self.image, (100, 100, 100), (size//2, size//2), size//2 - 2, 2)
        
        self.collected = False
    
    def update(self):
        """Check if collected"""
        # Check if still exists in Prolog
        px = (self.x - POSITIONS[0][0][0]) // 147 + 1  # Convert back to grid
        py = (self.y - POSITIONS[0][0][1]) // 147 + 1
        
        result = list(prolog.query(f"rock_pickup({px}, {py})."))
        if not result:
            self.collected = True
            self.x, self.y = (-999, -999)


def valid_move(hunter_obj):
    """avoid moving hunter into the wall before prolog do it"""
    facing = hunter_obj.rotation
    x, y = hunter_obj.x, hunter_obj.y

    if (
        (facing == 'right' and x == 695) or
        (facing == 'left' and x == 107) or
        (facing == 'up' and y == 107) or
        (facing == 'down' and y == 670)
    ):
        return False
    return True


def winner():
    """function to draw the winner screen"""
    text = 'WINNER: You managed to get the gold out!'

    font = pygame.font.Font(FONT, 30)
    text_surface = font.render(text, True, pygame.color.Color('white'))
    text_rect = text_surface.get_rect()
    text_rect.center = (WIDTH/2, HEIGHT/3)
    WIN.blit(text_surface, text_rect)

    score = list(prolog.query("h_score(X)"))[0]['X']
    text = 'Your score: {} point(s).'.format(score)
    text_surface = font.render(text, True, pygame.color.Color('white'))
    text_rect = text_surface.get_rect()
    text_rect.center = (WIDTH/2, HEIGHT/3 + 40)
    WIN.blit(text_surface, text_rect)

    pygame.display.update()
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()


def game_over():
    """function to draw the game over screen"""
    hunter_pos = list(list(prolog.query("w_hunter(X,Y,_)."))[0].values())
    query_params = f'({hunter_pos[0]},{hunter_pos[1]})'
    wumpus_hit = list(prolog.query(f'w_wumpus{query_params}.')) == [{}]
    pit_fall = list(prolog.query(f'w_pit{query_params}.')) == [{}]

    if wumpus_hit or pit_fall:
        score = list(prolog.query("h_score(X)"))[0]['X']
        if wumpus_hit:
            text = 'GAME OVER: Wumpus killed you!'
        elif pit_fall:
            text = 'GAME OVER: You fell into a pit!'

        font = pygame.font.Font(FONT, 30)
        text_surface = font.render(text, True, pygame.color.Color('white'))
        text_rect = text_surface.get_rect()
        text_rect.center = (WIDTH/2, HEIGHT/3)
        WIN.blit(text_surface, text_rect)

        text = 'Your score: {} point(s).'.format(score)
        text_surface = font.render(text, True, pygame.color.Color('white'))
        text_rect = text_surface.get_rect()
        text_rect.center = (WIDTH/2, HEIGHT/3 + 40)
        WIN.blit(text_surface, text_rect)

        pygame.display.update()
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    sys.exit()


def update_elems(hunter_obj):
    """update and draw the game elements"""
    x, y = hunter_obj.x + 20, hunter_obj.y - 75
    sensors = list(prolog.query("getSensors(X)."))[0]['X']
    stench, breeze, glitter = sensors
    if glitter:
        WIN.blit(W_GOLD, (x, y))
    elif stench and breeze:
        WIN.blit(W_BS, (x, y))
    elif stench:
        WIN.blit(W_STENCH, (x, y))
    elif breeze:
        WIN.blit(W_BREEZE, (x, y))

    game_over()  # game's over?


def update_objects(light, sprites, *elems):
    """update all the objects in the game"""
    sprites.update()
    [el.update() for el in elems]
    light.update(sprites.sprites()[0])


def draw_window(light, sprites, *elems):
    """update the window"""
    WIN.blit(MAP, (0, 0))
    [el.draw() for el in elems]
    sprites.draw(WIN)
    light.draw()
    update_elems(sprites.sprites()[0])
    pygame.display.update()


def user_controller(event, hunter, rock_aiming=None, turn_indicator=None):
    """user bindings to control the hunter"""
    # Check if player is stunned
    if list(prolog.query("is_player_stunned.")):
        print("⚠️ You are stunned! Cannot act this turn.")
        return
    
    # Rock throwing mode
    if rock_aiming and rock_aiming.aiming:
        if event.key == pygame.K_LEFT:
            rock_aiming.cycle_target(-1)
        elif event.key == pygame.K_RIGHT:
            rock_aiming.cycle_target(1)
        elif event.key == pygame.K_UP:
            rock_aiming.cycle_target(-4)  # Move up in grid
        elif event.key == pygame.K_DOWN:
            rock_aiming.cycle_target(4)   # Move down in grid
        elif event.key == pygame.K_SPACE:
            if rock_aiming.confirm_throw():
                # Process environment turn after throw
                list(prolog.query("process_environment_turn."))
                if turn_indicator:
                    turn_indicator.increment_turn()
        elif event.key == pygame.K_ESCAPE:
            rock_aiming.cancel()
        return
    
    # Normal movement
    if event.key == pygame.K_UP and valid_move(hunter):
        list(prolog.query("move."))
        list(prolog.query("process_environment_turn."))
        if turn_indicator:
            turn_indicator.increment_turn()
    if event.key == pygame.K_LEFT:
        list(prolog.query("left."))
        list(prolog.query("process_environment_turn."))
        if turn_indicator:
            turn_indicator.increment_turn()
    if event.key == pygame.K_RIGHT:
        list(prolog.query("right."))
        list(prolog.query("process_environment_turn."))
        if turn_indicator:
            turn_indicator.increment_turn()
    if event.key == pygame.K_s:
        list(prolog.query("shoot."))
        list(prolog.query("process_environment_turn."))
        if turn_indicator:
            turn_indicator.increment_turn()
    if event.key == pygame.K_g:
        # Try to grab gold or open chest
        hunter_pos = list(prolog.query("w_hunter(X,Y,_)."))[0]
        hx, hy = hunter_pos['X'], hunter_pos['Y']
        
        # Check for chest at this position
        chest_result = list(prolog.query(f"chest(_, {hx}, {hy}, _)."))
        if chest_result:
            list(prolog.query("open_chest."))
        elif list(prolog.query('w_hunter(X,Y,_), w_gold(X,Y), w_goal(0).')):
            list(prolog.query("grab(0)."))
        
        list(prolog.query("process_environment_turn."))
        if turn_indicator:
            turn_indicator.increment_turn()
    if event.key == pygame.K_c:
        # Try to collect rock
        list(prolog.query("collect_rock."))
        
        # Climb if at exit
        if list(prolog.query('w_hunter(1,1,_), w_goal(1).')):
            list(prolog.query("climb(1)."))
            winner()
    if event.key == pygame.K_r:
        # Start rock throwing mode
        if rock_aiming:
            hunter_pos = list(prolog.query("w_hunter(X,Y,_)."))[0]
            hx, hy = hunter_pos['X'], hunter_pos['Y']
            rock_aiming.start_aiming((hx, hy))


def main(args) -> None:
    """Main function to run the simulation."""

    if args.t_map:
        list(prolog.query("run(pygameMap)."))
    else:
        list(prolog.query("run(pygame)."))

    last = pygame.time.get_ticks()
    cooldown = FPS * 6

    hunter = Hunter(*list(prolog.query("w_hunter( X, Y, Z)."))[0].values())
    wumpus = Wumpus(*list(prolog.query("w_wumpus( X, Y)."))[0].values())
    light = Light()

    moving_sprites = pygame.sprite.Group()
    moving_sprites.add(hunter)
    moving_sprites.add(wumpus)

    gold = Gold(*list(prolog.query("w_gold( X, Y)."))[0].values())
    pit_values = list(prolog.query("w_pit( X, Y)."))
    pits = [Pit(*pit_val.values()) for pit_val in pit_values]
    
    # NEW: Load chests
    chests = []
    chest_values = list(prolog.query("chest(ID, X, Y, _)."))
    for chest_val in chest_values:
        chest = TreasureChest(chest_val['ID'], chest_val['X'], chest_val['Y'])
        chests.append(chest)
    
    # NEW: Load rock pickups
    rocks = []
    rock_values = list(prolog.query("rock_pickup(X, Y)."))
    for rock_val in rock_values:
        rock = RockPickup(rock_val['X'], rock_val['Y'])
        rocks.append(rock)
    
    # NEW: Initialize UI components
    fog_of_war = FogOfWar(grid_size=4, cell_size=147, prolog_engine=prolog)
    inventory_ui = InventoryDisplay(FONT, prolog_engine=prolog)
    rock_aiming_ui = RockAimingOverlay(POSITIONS, cell_size=147, prolog_engine=prolog, font_path=FONT)
    turn_indicator = TurnIndicator(FONT, prolog_engine=prolog)

    clock = pygame.time.Clock()
    while True:
        clock.tick(FPS)
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                print(pygame.mouse.get_pos())
            if event.type == pygame.KEYDOWN:
                if not args.is_agent:
                    user_controller(event, hunter, rock_aiming_ui, turn_indicator)

        # Update objects
        update_objects(light, moving_sprites, *pits, gold)
        for chest in chests:
            chest.update()
        for rock in rocks:
            rock.update()
        
        # Draw everything
        draw_window(light, moving_sprites, *pits, gold)
        
        # Draw chests and rocks
        for chest in chests:
            chest.draw()
        for rock in rocks:
            if not rock.collected:
                rock.draw()
        
        # NEW: Draw fog of war
        fog_of_war.draw(WIN, POSITIONS)
        
        # NEW: Draw UI
        inventory_ui.draw(WIN, position=(10, 10))
        turn_indicator.draw(WIN, position=(10, 650))
        rock_aiming_ui.draw(WIN, None)  # font parameter not used

        pygame.display.update()

        if list(prolog.query("w_hunter(1,1,_), w_goal(1).")):
            winner()

        if args.is_agent:
            now = pygame.time.get_ticks()
            if now - last >= cooldown:
                last = now
                list(prolog.query("runloop(-1)."))
                turn_indicator.increment_turn()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="AI Agent for Wumpus World game")

    parser.add_argument(
        '-user',
        dest='is_agent',
        action="store_false",
        default=True,
        help="enable test mode for user to test the game.",
    )

    parser.add_argument(
        '-map',
        dest='t_map',
        action="store_true",
        default=False,
        help="run simulation on traditional map.",
    )

    args = parser.parse_args()

    main(args)  # run main function
