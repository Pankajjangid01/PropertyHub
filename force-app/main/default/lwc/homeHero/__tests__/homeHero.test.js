import { createElement } from '@lwc/engine-dom';
import HomeHero from 'c/homeHero';

describe('c-home-hero', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the redesigned home page with navigation and footer', () => {
        const element = createElement('c-home-hero', {
            is: HomeHero
        });

        document.body.appendChild(element);

        const title = element.shadowRoot.querySelector('.hero-title');
        const navItems = element.shadowRoot.querySelectorAll('.menu-link');
        const footer = element.shadowRoot.querySelector('c-site-footer');

        expect(title.textContent).toBe('Explore properties through their projects, not through clutter.');
        expect(navItems).toHaveLength(2);
        expect(footer).not.toBeNull();
    });
});
