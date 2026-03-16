import { test, expect } from '@playwright/test';

test.describe('Flow E2E', () => {
  test('home has nav and links', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('link', { name: 'FLOW' }).first()).toBeVisible();
    await expect(page.getByRole('link', { name: 'Search Products' }).first()).toBeVisible();
    await expect(page.getByRole('link', { name: 'Login' }).first()).toBeVisible();
  });

  test('search: navigate, type, submit, see results', async ({ page }) => {
    await page.goto('/search');
    await expect(page.getByRole('heading', { name: 'Search Products' })).toBeVisible();
    const search = page.getByRole('searchbox', { name: /search food/i });
    await search.fill('apple');
    await page.getByRole('button', { name: 'Search' }).click();
    await expect(page.getByText(/Found \d+ result/)).toBeVisible({ timeout: 10000 });
    const firstResult = page.getByRole('link', { name: /Apple.*Apfel/ }).first();
    await expect(firstResult).toBeVisible();
  });

  test('search result count is grammatically correct (results not "result s")', async ({ page }) => {
    await page.goto('/search');
    const search = page.getByRole('searchbox', { name: /search food/i });
    await search.fill('apple');
    await page.getByRole('button', { name: 'Search' }).click();
    await expect(page.getByText(/Found \d+ results?$/)).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('result s')).not.toBeVisible();
  });

  test('product page: from search to product detail', async ({ page }) => {
    await page.goto('/search');
    const search = page.getByRole('searchbox', { name: /search food/i });
    await search.fill('apple');
    await page.getByRole('button', { name: 'Search' }).click();
    await page.getByRole('link').filter({ hasText: 'Apple' }).filter({ hasText: 'Apfel' }).first().click();
    await expect(page).toHaveURL(/\/product\/[a-f0-9-]+/);
    await expect(page.getByRole('heading', { name: 'Apple' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'Back to search' })).toBeVisible();
    await expect(page.getByRole('button', { name: /Add to favorites|Remove from favorites/ })).toBeVisible();
  });

  test('login page: form and tabs', async ({ page }) => {
    await page.goto('/login');
    await expect(page.getByRole('button', { name: 'Sign in' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'Create account' })).toBeVisible();
    await expect(page.getByPlaceholder('you@example.com')).toBeVisible();
    await page.getByRole('button', { name: 'Create account' }).click();
    await expect(page.getByRole('heading', { name: 'Create account' })).toBeVisible();
  });

  test('dashboard without auth redirects to login', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login/, { timeout: 10000 });
  });
});
