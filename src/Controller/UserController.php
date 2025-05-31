<?php

namespace App\Controller;


use App\Entity\User;
use App\Repository\UserRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\Security\Csrf\CsrfToken;
use Symfony\Component\Security\Csrf\CsrfTokenManagerInterface;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Security\Core\Authentication\Token\Storage\TokenStorageInterface;


class UserController extends AbstractController
{
    #[Route('/users', name: 'user_list')]
    public function index(UserRepository $userRepository): Response
    {
        $users = $userRepository->findAll();

        return $this->render('user/index.html.twig', [
            'users' => $users,
        ]);
    }

    #[Route('/user/{id}/block', name: 'user_block', methods: ['POST'])]
    public function block(int $id, Request $request, EntityManagerInterface $em, CsrfTokenManagerInterface $csrf): RedirectResponse
    {
        $token = $request->request->get('_token');
        if (!$csrf->isTokenValid(new CsrfToken('block' . $id, $token))) {
            throw $this->createAccessDeniedException('Invalid CSRF token');
        }

        $user = $em->getRepository(User::class)->find($id);
        if (!$user) {
            throw $this->createNotFoundException('User not found');
        }

        $user->setIsBlocked(true);
        $em->flush();

        $this->addFlash('success', 'User blocked successfully.');

        return $this->redirectToRoute('user_list');
    }

    #[Route('/users/batch-action', name: 'user_batch_action', methods: ['POST'])]
    public function batchAction(Request $request, UserRepository $userRepository, EntityManagerInterface $em, CsrfTokenManagerInterface $csrf): RedirectResponse
    {
        $userIds = $request->request->all('user_ids');
        $action = $request->request->get('action');

        if (empty($userIds) || !in_array($action, ['block', 'unblock', 'delete'])) {
            $this->addFlash('warning', 'No users selected or invalid action.');
            return $this->redirectToRoute('user_list');
        }


        $users = $userRepository->findBy(['id' => $userIds]);

        foreach ($users as $user) {
            switch ($action) {
                case 'block':
                    $user->setIsBlocked(true);
                    break;
                case 'unblock':
                    $user->setIsBlocked(false);
                    break;
                case 'delete':
                    $em->remove($user);
                    break;
            }
        }

        $em->flush();

        $this->addFlash('success', 'Action performed successfully.');

        return $this->redirectToRoute('user_list');
    }


    #[Route('/user/{id}/unblock', name: 'user_unblock', methods: ['POST'])]
    public function unblock(int $id, Request $request, EntityManagerInterface $em, CsrfTokenManagerInterface $csrf): RedirectResponse
    {
        $token = $request->request->get('_token');
        if (!$csrf->isTokenValid(new CsrfToken('unblock' . $id, $token))) {
            throw $this->createAccessDeniedException('Invalid CSRF token');
        }

        $user = $em->getRepository(User::class)->find($id);
        if (!$user) {
            throw $this->createNotFoundException('User not found');
        }

        $user->setIsBlocked(false);
        $em->flush();

        $this->addFlash('success', 'User unblocked successfully.');

        return $this->redirectToRoute('user_list');
    }

    #[Route('/user/{id}/delete', name: 'user_delete', methods: ['POST'])]
    public function delete(
        User $user,
        EntityManagerInterface $em,
        TokenStorageInterface $tokenStorage,
        Request $request,
        SessionInterface $session
    ): Response {
        if (!$this->isCsrfTokenValid('delete-user' . $user->getId(), $request->request->get('_token'))) {
            throw $this->createAccessDeniedException('Invalid CSRF token');
        }

        $currentUser = $tokenStorage->getToken()?->getUser();
        $isSelf = $currentUser === $user;

        if ($isSelf) {
            // Удаляем токен и сессию ДО удаления пользователя
            $tokenStorage->setToken(null);
            $session->invalidate();

            // ⚠️ Перенаправляем сразу на logout, не удаляя пользователя прямо сейчас
            // (если у тебя реализован app_logout, он сам очистит всё)
            return $this->redirectToRoute('app_register');
        }

        $em->remove($user);
        $em->flush();

        $this->addFlash('success', 'User deleted successfully.');
        return $this->redirectToRoute('user_list');
    }



}
